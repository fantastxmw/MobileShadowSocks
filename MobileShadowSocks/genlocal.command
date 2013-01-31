#!/bin/bash
NOWDIR="$(dirname "$0")"
cd "$NOWDIR"
genstrings *.m -o en.lproj
