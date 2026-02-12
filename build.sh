#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Clone the Flutter repository
if [ -d "flutter" ]; then
    echo "Flutter directory already exists"
else
    git clone https://github.com/flutter/flutter.git -b stable
fi

# Add the flutter tool to the path
export PATH="$PATH:`pwd`/flutter/bin"

# Enable web support
flutter config --enable-web

# Clean and get dependencies
flutter clean
flutter pub get

# Build the web application
# --no-tree-shake-icons is often needed in CI/CD environments like Vercel
flutter build web --release --no-tree-shake-icons
