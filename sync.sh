#!/bin/bash
cd ~/.openclaw/workspace
git add .
git commit -m "memory update $(date '+%Y-%m-%d %H:%M')"
git push origin main
