#!/bin/sh
# Run studfy with environment variables loaded from .env
flutter run --dart-define-from-file=.env "$@"
