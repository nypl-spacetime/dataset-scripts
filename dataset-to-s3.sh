#!/bin/bash

ETL_OUTPUT_DIR=`spacetime-config etl.outputDir`
: "${ETL_OUTPUT_DIR:?Please install spacetime-config and set the etl.outputDir configuration option}"

re="(.*)\.(.*)"
if [[ $1 =~ $re ]]; then
  DATASET=${BASH_REMATCH[1]}
  STEP=${BASH_REMATCH[2]}
else
  echo "Please supply one command-line argument of the following form: DATASET.STEP" >&2
  exit
fi

SOURCE_DIR=$ETL_OUTPUT_DIR/$STEP/$DATASET

if ! [[ -d "$SOURCE_DIR" && -x "$SOURCE_DIR" ]]; then
  echo "Directory does not exist: $SOURCE_DIR" >&2
  exit
fi

TARGET_DIR=$ETL_OUTPUT_DIR/.spacetime-to-s3/$DATASET

# Empty TARGET_DIR
rm -rf $TARGET_DIR
mkdir -p $TARGET_DIR

# Copy all dataset subdirectories from SOURCE_DIR to TARGET_DIR
cp -p $SOURCE_DIR/* $TARGET_DIR

if [ -f $TARGET_DIR/$DATASET.objects.ndjson ]
then
  # Convert NDJSON to GeoJSON using spacetime-cli
  spacetime-to-geojson $TARGET_DIR/$DATASET.objects.ndjson > $TARGET_DIR/$DATASET.geojson

  # Read JSON Paths used for flattening Object data, using empty array [] as default
  JSON_PATHS="$(cat $SOURCE_DIR/$DATASET.dataset.json | jq -c  '.flattenPaths // ["$.data"]')"

  # Convert Object NDJSON to GeoJSON, with flattened Object data
  spacetime-to-geojson -f $JSON_PATHS $TARGET_DIR/$DATASET.objects.ndjson > $TARGET_DIR/$DATASET.flattened.geojson

  # Convert Object NDJSON to CSV, with flattened Object data
  spacetime-to-csv -f $JSON_PATHS $TARGET_DIR/$DATASET.objects.ndjson > $TARGET_DIR/$DATASET.csv

  # Create sample GeoJSON with at most 100 objects
  exists() { type -t "$1" > /dev/null 2>&1; }

  if exists gshuf; then
    SHUF=gshuf
  else
    SHUF=shuf
  fi

  $SHUF -n 100 $TARGET_DIR/$DATASET.objects.ndjson | spacetime-to-geojson > $TARGET_DIR/$DATASET.sample.geojson

  # We don't need etl-results.json - all important data is present in datapackage.json
  rm $TARGET_DIR/etl-results.json

  # We also don't need the original dataset descriptor, all info is present in datapackage.json as well
  rm $TARGET_DIR/$DATASET.dataset.json
fi

# Create ZIP file with all dataset files
cd $TARGET_DIR
zip -r $DATASET.zip ./

aws s3 sync $TARGET_DIR s3://spacetime-nypl-org/datasets/$DATASET \
  --delete --profile spacetime

rm -rf $ETL_OUTPUT_DIR/.spacetime-to-s3/$DATASET
rm -rf $ETL_OUTPUT_DIR/.spacetime-to-s3
