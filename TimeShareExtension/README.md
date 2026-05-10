# Share Extension

This directory contains the iOS share extension entry point.

Current behavior:

- accepts images from the iOS share sheet
- copies shared image payloads into the app group container
- writes a JSON import manifest for the main app
- lets the main app consume pending shared batches when it starts or returns to the foreground

Remaining work:

1. add visible success and failure feedback inside the extension UI
2. add cleanup rules for old consumed batches after the main app has imported them
