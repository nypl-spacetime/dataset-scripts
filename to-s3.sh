#!/bin/bash

DATA_DIR=/Users/bertspaan/data/spacetime/etl/transform

for dir in $DATA_DIR/*; do
  if [[ -d $dir ]]; then
    dataset="$(basename $dir)"

    # Convert NDJSON to GeoJSON using spacetime-cli
    spacetime-to-geojson $dir/$dataset.objects.ndjson > $dir/$dataset.geojson

    # Create sample GeoJSON with at most 100 objects
    gshuf -n 100 $dir/$dataset.objects.ndjson | spacetime-to-geojson > $dir/$dataset.sample.geojson

    # Create ZIP file with all dataset files, remove existing ZIP file first
    cd $dir
    rm -f .DS_Store
    rm -f $dataset.zip
    zip -r $dataset.zip ./
  fi
done

aws s3 sync $DATA_DIR s3://spacetime-nypl-org/datasets/ --exclude "*" \
--include "*.json" --include "*.ndjson" --include "*.zip" --include "*.geojson" \
--delete --profile spacetime
