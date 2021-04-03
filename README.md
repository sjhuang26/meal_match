# Meal Match

## Firebase emulator

```
nvm use 12.20.1
jabba use openjdk@1.11.0
cd functions
npm run build
cd ..
firebase emulators:start --import=./firebase-emulator --export-on-exit
```

## Tricky issues

If the app randomly crashes with "Local module descriptor class for providerinstaller not found",
make sure that all the necessary Firebase collections exist. See
https://github.com/flutter/flutter/issues/66261
