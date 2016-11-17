#!/usr/bin/env bash

export METEOR_PACKAGE_DIRS='packages'

if [ "$PORT" ]; then
  meteor test-packages ./ --port $PORT
else
   meteor test-packages ./
fi
