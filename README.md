# Scripts for NYC Space/Time Directory

## Publish NYC Space/Time Directory data to S3

[`dataset-to-s3.sh`](dataset-to-s3.sh) uploads a single NYC Space/Time Directory dataset to S3. The script also creates a GeoJSON file from the NDJSON objects file, and zips the dataset.

[`all-etl-data-to-s3.sh`](all-etl-data-to-s3) copies _all_ output (final datasets and intermediate steps) of NYC Space/Time Directory's [ETL tool](https://github.com/nypl-spacetime/spacetime-etl) to S3.

## Prerequisites

1. First, install [spacetime-config](https://github.com/nypl-spacetime/spacetime-config) and set the `etl.outputDir` configuration option. See [spacetime-etl](https://github.com/nypl-spacetime/spacetime-etl) for more information.
2. Install [spacetime-cli](https://github.com/nypl-spacetime/spacetime-cli)
3. Install [aws-cli](https://github.com/aws/aws-cli)
4. Add AWS credentials to [`~/.aws/credentials`](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html#cli-config-files), using the `spacetime` profile:

```
[spacetime]
echo aws_access_key_id = AWS_ACCESS_KEY_ID
echo aws_secret_access_key = AWS_SECRET_ACCESS_KEY
```

### Usage

To publish a single dataset to S3, run:

    ./dataset-to-s3 DATASET.STEP

For example:

    ./dataset-to-s3 mapwarper.transform

To sync _all_ output of NYC Space/Time Directory's [ETL tool](https://github.com/nypl-spacetime/spacetime-etl) to S3, run:

    ./all-etl-data-to-s3
