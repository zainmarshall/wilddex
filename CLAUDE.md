# WildDex - "A Pokédex for Animals"

Wildlife species identification app: photograph animals, identify them via ML, track discoveries, earn badges.

## Tech Stack

### Flutter App (`/wilddex`)
- **Framework**: Flutter (Dart 3.8.1+)
- **State Management**: Provider (`UserDataProvider`, `SettingsProvider`)
- **Local DB**: Isar (NoSQL) for species/taxa caching
- **Persistence**: SharedPreferences for user data (discoveries, sightings, badges)
- **Camera**: `camera` package with pinch-to-zoom
- **HTTP**: `http` package → POST `/predict` with multipart image upload
- **HTML rendering**: `flutter_html` for species descriptions from Wikipedia

### Backend (`/backend`)
- **Framework**: FastAPI (Python 3.11) + Uvicorn
- **ML Model**: Google SpeciesNet 5.0.3 (YOLOv5 detector + EfficientNet V2 M classifier)
- **Inference modes**: Direct (in-memory) or CLI subprocess fallback
- **Geofencing**: 2000+ species geographic filtering by country
- **Deployment**: Docker (python:3.11-slim), exposes port 8080
- **Cloud**: Currently deployed on Google Cloud Run at `speciesnet-api-299368091467.us-east4.run.app`

### Parser (`/parser`)
- **Purpose**: Scrapes Wikidata/Wikipedia for species taxonomy, descriptions, images, range maps
- **Output**: `species.json`, `taxa.json`, images → consumed by Flutter app
- **APIs**: Wikidata SPARQL, Wikipedia REST, Wikimedia Commons

## Key Architecture

```
User → Flutter Camera → POST /predict (image) → FastAPI → SpeciesNet ensemble
                                                           ├── YOLOv5 detector (animal bbox)
                                                           └── EfficientNet classifier (species ID)
                                                               └── Geofence filter
Result ← species match ← genus+species lookup ← prediction response
```

## API Endpoints
- `POST /predict` — Upload image, get species prediction (genus, species, common_name, confidence, bounding_box)
- `GET /health` — Health check
- `GET /ready` — Model loaded status

## App Screens (5 tabs)
1. **Dex** — Browse species catalog by family/class, search, filter discovered
2. **Camera** — Capture photo → predict → show result → mark discovered
3. **Park Field Guide** — Browse species by park location with completion tracking
4. **Gallery** — Photo history grouped by species
5. **Profile** — Stats, badges, streak, level system (Novice → Mythic)

## Constants & Config
- Cloud API: `https://speciesnet-api-299368091467.us-east4.run.app`
- Image CDN: `https://storage.googleapis.com/wilddex-species-images`
- Settings toggle for local API (`http://localhost:8000` or custom host)
- Settings toggle for crop model (faster inference)

## Known Bugs & Issues

### Backend
- CORS open to all origins (`allow_origins=["*"]`)
- No file upload validation (size, MIME type)
- No inference timeout — hung requests exhaust thread pool
- Direct inference mode import error (falls back to CLI silently)
- Supabase in requirements but unused

### Flutter App
- Range map URL getter broken — loop returns on first iteration (species.dart ~line 93-101)
- Hardcoded subspecies mapping only for dogs (canis lupus familiaris)
- Bounding box assumes 320x320 — breaks on other image sizes
- No API timeout/error handling in camera flow
- BadgeEngine.loadDefinitions() called twice in ProfileScreen
- Test files are empty stubs

### Parser
- Pillow not in requirements.txt but imported for image conversion
- Duplicate `time.sleep(RATE_LIMIT)` — runs at half speed
- Inconsistent taxonomy naming (e.g., "animal" vs "Animalia", "mammal" vs "Mammalia")
- Filename typo: `instrctuions.md`

## Build & Run

```bash
# Backend (local)
cd backend
SPECIESNET_REPO_PATH=$(pwd)/cammertrapai SPECIESNET_MODE=direct uvicorn main:app --host 0.0.0.0 --port 8000

# Backend (Docker)
cd backend && docker build -t wilddex-backend . && docker run -p 8080:8080 wilddex-backend

# Flutter app
cd wilddex && flutter run

# Parser
cd parser && pip install -r requirements.txt && python parse.py
```

## Environment Variables (Backend)
- `PORT` — Server port (default 8080)
- `SPECIESNET_MODE` — "auto", "direct", or "cli"
- `SPECIESNET_REPO_PATH` — Path to cammertrapai directory
- `SPECIESNET_USE_CROPS` — "0" or "1" for crop-based inference
- `MODEL_LOAD_MODE` — "lazy" or "eager"
- `LOG_LEVEL` — Python logging level

## Data Pipeline
1. Parser scrapes Wikidata/Wikipedia → `species.json`, `taxa.json`, images
2. `normalize_assets.py` creates `species_normalized.json`, `taxa_normalized.json` with IDs
3. Flutter app loads normalized JSON from assets at startup
4. Isar DB caches for fast subsequent loads
