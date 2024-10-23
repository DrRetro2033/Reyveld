#!/bin/bash

APP_NAME="my_app"
INSTALL_DIR="/usr/local/bin"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (using sudo)"
  exit 1
fi

# Copy the executable to the install directory
cp "$APP_NAME" "$INSTALL_DIR/$APP_NAME"
chmod +x "$INSTALL_DIR/$APP_NAME"

# Verify installation
if [ -f "$INSTALL_DIR/$APP_NAME" ]; then
  echo "$APP_NAME installed successfully!"
else
  echo "Failed to install $APP_NAME."
fi
