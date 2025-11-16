#!/usr/bin/env bash
set -e

# 1) Clean old build output
rm -rf public/*
rm -rf docs/*

# 2) RUN YOUR STATIC SITE BUILD HERE
# Example (uncomment the one you actually use):
# hugo
# zola build
# marmite build

# 3) Copy build output to docs/ for GitHub Pages
cp -r public/* docs/
./scripts/inject-seo.sh
