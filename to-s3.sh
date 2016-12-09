#!/bin/bash

DATA_DIR=/Users/bertspaan/data/spacetime/etl/transform

for dir in $DATA_DIR/*; do
  if [[ -d $dir ]]; then
    dataset="$(basename $dir)"
    spacetime-to-geojson $dir/$dataset.objects.ndjson > $dir/$dataset.geojson
    zip -r $dir/$dataset.zip $dir/
  fi
done

aws s3 sync $DATA_DIR s3://spacetime-nypl-org/datasets/ --exclude "*" \
--include "*.json" --include "*.ndjson" --include "*.zip" --include "*.geojson" \
--delete --profile spacetime
