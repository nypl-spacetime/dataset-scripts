#!/bin/bash

SPACETIME_ETL_DIR=`spacetime-config etl.outputDir`

: "${SPACETIME_ETL_DIR:?Please install spacetime-config and set the etl.outputDir configuration option}"

STEPS=( transform aggregate )
TARGET_DIR=/tmp/spacetime-to-s3

# Empty TARGET_DIR
rm -rf $TARGET_DIR
mkdir $TARGET_DIR

for step in "${STEPS[@]}"
do
  SOURCE_DIR=$SPACETIME_ETL_DIR/$step

  # Copy all dataset subdirectories from SOURCE_DIR to TARGET_DIR
  # TODO: only *.ndjson and *.json
  cp -p -r $SOURCE_DIR/* $TARGET_DIR
done

for dir in $TARGET_DIR/*; do
  if [[ -d $dir ]]; then
    dataset="$(basename $dir)"

    if [ -f $dir/$dataset.objects.ndjson ]
    then
      # Convert NDJSON to GeoJSON using spacetime-cli
      spacetime-to-geojson $dir/$dataset.objects.ndjson > $dir/$dataset.geojson

      # Create sample GeoJSON with at most 100 objects
      exists() { type -t "$1" > /dev/null 2>&1; }

      if exists gshuf; then
        SHUF=gshuf
      else
        SHUF=shuf
      fi

      $SHUF -n 100 $dir/$dataset.objects.ndjson | spacetime-to-geojson > $dir/$dataset.sample.geojson
    fi

    # Create ZIP file with all dataset files
    cd $dir
    zip -r $dataset.zip ./
  fi
done

aws s3 sync $TARGET_DIR s3://spacetime-nypl-org/datasets/ --exclude "*" \
  --include "*.json" --include "*.ndjson" --include "*.zip" --include "*.geojson" \
  --delete --profile spacetime
