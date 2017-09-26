#!/bin/bash

ETL_OUTPUT_DIR=`spacetime-config etl.outputDir`

: "${ETL_OUTPUT_DIR:?Please install spacetime-config and set the etl.outputDir configuration option}"

aws s3 sync $ETL_OUTPUT_DIR s3://spacetime-nypl-org/etl/ \
  --delete --profile spacetime
