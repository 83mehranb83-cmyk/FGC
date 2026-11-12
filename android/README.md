# FGC Android (offline)

This project packages the existing FGC web interface as an Android application. The original `index.html` is bundled in the APK assets and loads locally; no network permission or remote web server is required.

## Build
Run the GitHub Actions workflow **Build FGC Offline APK**. Download the `FGC-offline-debug-apk` artifact from the successful run.

## Local data
The app uses the existing FGC browser storage model (localStorage) inside the Android WebView. Data stays on this device/app installation. Use the app's backup export regularly and keep the JSON backup outside the app.

## Notes
- Photos are selected through Android's file picker.
- The web app's PDF print view opens in a secondary WebView.
- This debug APK is for installation/testing; a signed release build can be prepared separately.
