#!/bin/bash

# Exit on error
set -e

# 1. Define Flutter version
FLUTTER_VERSION="3.35.3"

# 2. Clone Flutter SDK
echo "Cloning Flutter SDK version $FLUTTER_VERSION..."
git clone https://github.com/flutter/flutter.git --depth 1 --branch $FLUTTER_VERSION

# 3. Set Flutter path and give it priority
echo "Setting Flutter PATH..."
FLUTTER_PATH="$(pwd)/flutter/bin"
export PATH="$FLUTTER_PATH:$PATH"

# 4. Verify which flutter is being used
echo "--- Verifying Flutter installation ---"
echo "Flutter executable path: $(which flutter)"
echo "Flutter version output:"
flutter --version
echo "------------------------------------"

# 5. Install dependencies
echo "Installing dependencies..."
flutter pub get

# 6. Generate code with build_runner
echo "Running build_runner to generate code..."
flutter pub run build_runner build --delete-conflicting-outputs

# 7. Build the web application
echo "Building Flutter web app..."
flutter build web --release

echo "Build finished successfully!"