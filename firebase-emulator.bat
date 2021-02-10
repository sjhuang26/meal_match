nvm use 12.20.1
jabba use openjdk@1.11.0
cd functions
npm run build
cd ..
firebase emulators:start --import=./firebase-emulator --export-on-exit
