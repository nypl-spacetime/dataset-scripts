#!/bin/bash

SOURCE_DIR=/Users/bertspaan/data/spacetime/etl/transform

TARGET_BASE=/Users/bertspaan/data/spacetime
TARGET_DIR=$TARGET_BASE/to-s3

# Empty TARGET_DIR
rm -rf $TARGET_DIR
mkdir $TARGET_DIR

# Copy all dataset subdirectories from SOURCE_DIR to TARGET_DIR
# TODO: only *.ndjson and *.json
cp -r $SOURCE_DIR/* $TARGET_DIR

for dir in $TARGET_DIR/*; do
  if [[ -d $dir ]]; then
    dataset="$(basename $dir)"

    # Convert NDJSON to GeoJSON using spacetime-cli
    spacetime-to-geojson $dir/$dataset.objects.ndjson > $dir/$dataset.geojson

    # Create sample GeoJSON with at most 100 objects
    gshuf -n 100 $dir/$dataset.objects.ndjson | spacetime-to-geojson > $dir/$dataset.sample.geojson

    # Create ZIP file with all dataset files, remove existing ZIP file first
    cd $dir
    zip -r $dataset.zip ./
  fi
done

aws s3 sync $TARGET_DIR s3://spacetime-nypl-org/datasets/ --exclude "*" \
  --include "*.json" --include "*.ndjson" --include "*.zip" --include "*.geojson" \
  --delete --profile spacetime
