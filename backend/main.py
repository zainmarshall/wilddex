
# main.py

from fastapi import FastAPI, HTTPException, UploadFile, File, Query
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
import shutil
import os
import uuid
import subprocess
import json
import tempfile
import asyncio
import logging
import importlib
import sys
from typing import Optional
from pydantic import BaseModel

MAX_UPLOAD_SIZE = 10 * 1024 * 1024  # 10 MB
ALLOWED_MIME_PREFIXES = ("image/",)
INFERENCE_TIMEOUT = int(os.getenv("INFERENCE_TIMEOUT", "60"))

# NOTE: supabase import removed (unused). Add back if needed.

class PredictionResponse(BaseModel):
    genus: str
    species: str
    common_name: str
    scientific_name: str
    bounding_box: list[float]
    confidence: float


logger = logging.getLogger("speciesnet_api")
logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO"))

app = FastAPI(title="SpeciesNet API", version="0.1.1")

_cors_origins_env = os.getenv("CORS_ORIGINS", "").strip()
_cors_origins = [o.strip() for o in _cors_origins_env.split(",") if o.strip()] if _cors_origins_env else ["*"]

app.add_middleware(
    CORSMiddleware,
    allow_origins=_cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

def _parse_prediction(raw_prediction: dict) -> PredictionResponse:
    parts = (raw_prediction.get("prediction") or "").split(";")
    genus = parts[4] if len(parts) > 4 else ""
    species = parts[5] if len(parts) > 5 else ""
    common_name = parts[6] if len(parts) > 6 else ""
    scientific_name = raw_prediction.get("scientific_name") or raw_prediction.get(
        "binomial"
    )
    if not scientific_name:
        scientific_name = f"{genus} {species}".strip()
    bbox = raw_prediction.get("detections", [{}])[0].get("bbox", [0, 0, 0, 0])
    confidence = float(raw_prediction.get("prediction_score", 0.0))
    return PredictionResponse(
        genus=genus,
        species=species,
        common_name=common_name,
        scientific_name=scientific_name,
        bounding_box=bbox,
        confidence=confidence,
    )


def _resolve_repo_path() -> Optional[str]:
    repo_path = os.getenv("SPECIESNET_REPO_PATH")
    if repo_path:
        return repo_path
    local_path = os.path.join(os.path.dirname(__file__), "cammertrapai")
    if os.path.isdir(local_path):
        return local_path
    return None


def _maybe_add_repo_path() -> None:
    repo_path = _resolve_repo_path()
    if not repo_path:
        return
    if repo_path not in sys.path:
        sys.path.insert(0, repo_path)


def _import_speciesnet():
    _maybe_add_repo_path()
    try:
        return importlib.import_module("speciesnet")
    except Exception:
        return None


class _DirectSpeciesNet:
    def __init__(self, use_crops: bool):
        self.use_crops = use_crops
        self.speciesnet_module = _import_speciesnet()
        if self.speciesnet_module is None:
            raise RuntimeError("speciesnet module not available")
        model_name = _resolve_model_name(self.speciesnet_module, use_crops)
        components = "all"
        self.model = self.speciesnet_module.SpeciesNet(
            model_name,
            components=components,
            geofence=True,
            multiprocessing=False,
        )

    def predict_file(self, image_path: str):
        run_mode = os.getenv("SPECIESNET_RUN_MODE", "single_thread")
        batch_size = int(os.getenv("SPECIESNET_BATCH_SIZE", "8"))
        return self.model.predict(
            filepaths=[image_path],
            run_mode=run_mode,
            batch_size=batch_size,
            progress_bars=False,
        )


def _resolve_model_name(speciesnet_module, use_crops: bool) -> str:
    model_env = "SPECIESNET_MODEL_CROP" if use_crops else "SPECIESNET_MODEL_FULL"
    model_name = os.getenv(model_env)
    if model_name:
        return model_name
    return getattr(speciesnet_module, "DEFAULT_MODEL", "kaggle:google/speciesnet/pyTorch/v4.0.2a/1")


def _run_speciesnet_cli(temp_dir: str, output_json_path: str, use_crops: bool) -> None:
    """Fallback subprocess execution of the original CLI.
    Using capture_output to supply helpful diagnostics if it fails.
    """
    crop_flag = os.getenv("SPECIESNET_CLI_CROP_FLAG", "").strip()
    speciesnet_module = _import_speciesnet()
    model_name = _resolve_model_name(speciesnet_module, use_crops) if speciesnet_module else None
    cmd = [
        sys.executable,
        "-m",
        "speciesnet.scripts.run_model",
        "--folders",
        temp_dir,
        "--predictions_json",
        output_json_path,
    ]
    if model_name:
        cmd.extend(["--model", model_name])
    if use_crops and crop_flag:
        cmd.append(crop_flag)
    env = os.environ.copy()
    repo_path = _resolve_repo_path()
    if repo_path:
        env["PYTHONPATH"] = f"{repo_path}:{env.get('PYTHONPATH', '')}".strip(":")
    result = subprocess.run(
        cmd,
        env=env,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        raise RuntimeError(
            f"SpeciesNet CLI failed (exit {result.returncode})\nSTDOUT:\n{result.stdout}\nSTDERR:\n{result.stderr}"
        )


_DIRECT_PREDICTORS = {True: None, False: None}
_DIRECT_MODEL_LOCK = asyncio.Lock()
_MODEL_READY = False
_SPECIESNET_MODE = os.getenv("SPECIESNET_MODE", "auto").lower()
_DEFAULT_USE_CROPS = os.getenv("SPECIESNET_USE_CROPS", "0") == "1"


async def _load_model_once() -> None:
    global _MODEL_READY
    if _MODEL_READY:
        return
    async with _DIRECT_MODEL_LOCK:
        if _MODEL_READY:
            return
        if _SPECIESNET_MODE == "cli":
            _MODEL_READY = True
            return
        for use_crops in (False, True):
            if _DIRECT_PREDICTORS[use_crops] is not None:
                continue
            try:
                _DIRECT_PREDICTORS[use_crops] = _DirectSpeciesNet(use_crops)
            except Exception as e:
                logger.info("Direct model load failed (use_crops=%s): %s", use_crops, e)
        _MODEL_READY = True


_PERSIST_TEMP_DIR = os.getenv("PERSIST_TEMP_DIR", "1") == "1"
_SHARED_TEMP_DIR: Optional[str] = None


def _ensure_shared_temp_dir() -> str:
    global _SHARED_TEMP_DIR
    if _SHARED_TEMP_DIR and os.path.isdir(_SHARED_TEMP_DIR):
        return _SHARED_TEMP_DIR
    base = tempfile.gettempdir()
    path = os.path.join(base, "speciesnet_api")
    os.makedirs(path, exist_ok=True)
    _SHARED_TEMP_DIR = path
    return path


async def _generate_prediction(file: UploadFile, use_crops: bool) -> PredictionResponse:
    # Ensure model loaded (lazy) if we eventually add direct inference.
    if os.getenv("MODEL_LOAD_MODE", "lazy") == "eager":
        await _load_model_once()
    else:
        # Lazy: load only if first request hits and not yet loaded (non-blocking background task).
        if not _MODEL_READY:
            asyncio.create_task(_load_model_once())

    if _PERSIST_TEMP_DIR:
        parent_dir = _ensure_shared_temp_dir()
        temp_dir = os.path.join(parent_dir, str(uuid.uuid4()))
        os.makedirs(temp_dir, exist_ok=True)
        temp_dir_cm = None
    else:
        temp_dir_cm = tempfile.TemporaryDirectory()
        temp_dir = temp_dir_cm.name

    image_filename = f"{uuid.uuid4()}.jpg"
    image_path = os.path.join(temp_dir, image_filename)
    with open(image_path, "wb") as f:
        shutil.copyfileobj(file.file, f)

    prediction = None
    if _SPECIESNET_MODE in ("auto", "direct"):
        direct = _DIRECT_PREDICTORS.get(use_crops)
        if direct is None:
            await _load_model_once()
            direct = _DIRECT_PREDICTORS.get(use_crops)
        if direct is not None:
            try:
                result = await asyncio.wait_for(
                    asyncio.to_thread(direct.predict_file, image_path),
                    timeout=INFERENCE_TIMEOUT,
                )
                raw_prediction = _extract_raw_prediction(result)
                prediction = _parse_prediction(raw_prediction)
            except asyncio.TimeoutError:
                logger.error("Direct inference timed out after %ds", INFERENCE_TIMEOUT)
                if _SPECIESNET_MODE == "direct":
                    raise RuntimeError(f"Inference timed out after {INFERENCE_TIMEOUT}s")
                logger.info("Falling back to CLI after timeout")
            except Exception as e:
                if _SPECIESNET_MODE == "direct":
                    raise
                logger.info("Direct prediction failed; falling back to CLI: %s", e)

    if prediction is None:
        output_json_path = os.path.join(temp_dir, "output.json")
        await asyncio.wait_for(
            asyncio.to_thread(_run_speciesnet_cli, temp_dir, output_json_path, use_crops),
            timeout=INFERENCE_TIMEOUT,
        )
        with open(output_json_path, "r") as f:
            raw = json.load(f)
        if not raw.get("predictions"):
            raise ValueError("No predictions returned by SpeciesNet")
        raw_prediction = raw["predictions"][0]
        prediction = _parse_prediction(raw_prediction)

    # Cleanup if persistent temp dir is enabled (remove subfolder) to avoid disk growth.
    if _PERSIST_TEMP_DIR and os.path.isdir(temp_dir):
        try:
            shutil.rmtree(temp_dir)
        except Exception:  # pragma: no cover
            logger.warning("Failed to cleanup temp dir %s", temp_dir)
    elif temp_dir_cm is not None:
        temp_dir_cm.cleanup()

    return prediction


def _extract_raw_prediction(result):
    if isinstance(result, PredictionResponse):
        return result.dict()
    if isinstance(result, dict):
        if "predictions" in result and result["predictions"]:
            return result["predictions"][0]
        if "prediction" in result or "prediction_score" in result:
            return result
        if result:
            first_value = next(iter(result.values()))
            if isinstance(first_value, dict):
                return first_value
    if isinstance(result, list) and result:
        first = result[0]
        if isinstance(first, dict):
            return first
    raise ValueError("Unexpected prediction result format")


@app.post("/predict", response_model=PredictionResponse)
async def predict(
    file: UploadFile = File(...),
    use_crops: bool = Query(default=_DEFAULT_USE_CROPS),
):
    # Validate MIME type
    content_type = file.content_type or ""
    if not any(content_type.startswith(prefix) for prefix in ALLOWED_MIME_PREFIXES):
        raise HTTPException(status_code=400, detail=f"Invalid file type: {content_type}. Only images are accepted.")

    # Validate file size (read up to limit + 1 byte to detect oversized files)
    contents = await file.read()
    if len(contents) > MAX_UPLOAD_SIZE:
        raise HTTPException(status_code=400, detail=f"File too large ({len(contents)} bytes). Maximum is {MAX_UPLOAD_SIZE} bytes.")
    await file.seek(0)

    try:
        return await _generate_prediction(file, use_crops)
    except Exception as e:
        logger.exception("Prediction failed")
        return JSONResponse(status_code=500, content={"error": str(e)})


@app.get("/health")
async def health() -> dict:
    return {"status": "ok"}


@app.get("/ready")
async def ready() -> dict:
    return {"model_loaded": _MODEL_READY}


@app.on_event("startup")
async def _startup() -> None:
    if os.getenv("MODEL_LOAD_MODE", "lazy") == "eager":
        await _load_model_once()
        logger.info("Model eagerly loaded at startup (ready=%s)", _MODEL_READY)
