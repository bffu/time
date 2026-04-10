# Share Extension Placeholder

This directory contains the initial share extension entry point.

Current behavior:

- accepts images from the iOS share sheet
- validates that at least one shared attachment conforms to `public.image`
- immediately completes the extension request

What still needs to be implemented:

1. copy shared image payloads into the app group container
2. create an import manifest that the main app can read
3. trigger the main app to refresh imported screenshots
4. add basic user feedback for success and failure states
