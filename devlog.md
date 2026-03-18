## WildDex Devlog 

I realized I probably won't be able to host this app on the iOS appstore because of a lack of funds, but I won't give up. I decided I can compile to android as a .apk and compile to a PWA for ios. 

### What Changed

1. **Backend hardening** (`backend/main.py`)
   - CORS now configurable via `CORS_ORIGINS` env var instead of wide-open `*`.
   - Inference calls wrapped with 60s timeout — no more hung requests eating the thread pool.
   - File uploads validated: rejects non-image MIME types and files over 10MB.

2. **M1 MacBook deployment setup**
   - I want image req to be fast but cheap for me, so I decided to deploy it on this old M1 macbook of mine which will act as a server for the next few weeks. 
   - `setup_m1_deployment.sh` - one-command setup: installs the service, configures cron, walks through Cloudflare Tunnel.

3. **Range map URL fix** (`species.dart`)
   - The `apiRangeMapUrl` never tried alternate file extensions so it failed sometimes, works now. 

4. **Bounding box fix** (`prediction_result_screen.dart`)
   - Image display size now computed from layout constraints instead of hardcoded 320x320. Bbox overlay scales to match.

5. **Smarter species lookup**
   - Replaced the single hardcoded `canis familiaris` mapping with a multi-strategy resolver: exact match → subspecies table → partial match → genus-only fallback. Handles dogs, domestic cats, cattle.

6. **API error handling** (`camera_tab.dart`)
   - 30s timeout on prediction calls. User-friendly error screen on failure instead of silent crashes. Upload switched to `fromBytes()` for cross-platform compat.

7. **Cross-platform image pipeline**
   - New `CapturedImage` class wraps `Uint8List` bytes + optional file path. All screens now consume bytes instead of `dart:io` `File` — works on web and native.

8. **iOS PWA support**
   - `WebCameraTab` uses `image_picker` → opens native iOS camera picker in Safari.
   - Platform routing via `camera_host.dart`: web gets `WebCameraTab`, native gets the real `CameraController`.
   - `manifest.json` + `index.html` updated with proper PWA metadata, iOS meta tags, and WildDex branding.

