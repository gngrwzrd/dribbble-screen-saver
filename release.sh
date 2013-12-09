#!/bin/bash
VERSION=$1
ARCHIVE=$2
mkdir -p "Releases/${VERSION}"
cp -r "${ARCHIVE}/Products/Users/aaronsmith/Library/Screen Savers/HotShotsScreenSaver.saver" "Releases/${VERSION}/HotShotsScreenSaver.saver"
cd "Releases/${VERSION}/"
zip -r "HotShotsScreenSaver.saver.zip" "HotShotsScreenSaver.saver"
