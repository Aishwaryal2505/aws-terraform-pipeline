import boto3
import csv
import io
from datetime import datetime, timezone

s3 = boto3.client("s3")
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table("ProcessedFilesTerraform")


def lambda_handler(event, context):
    record = event["Records"][0]
    bucket_name = record["s3"]["bucket"]["name"]
    file_key = record["s3"]["object"]["key"]

    response = s3.get_object(Bucket=bucket_name, Key=file_key)
    file_content = response["Body"].read().decode("utf-8")

    csv_reader = csv.reader(io.StringIO(file_content))
    rows = list(csv_reader)
    row_count = len(rows) - 1 if len(rows) > 0 else 0

    table.put_item(
        Item={
            "file_id": file_key,
            "bucket": bucket_name,
            "row_count": row_count,
            "processed_at": datetime.now(timezone.utc).isoformat(),
        }
    )

    return {
        "statusCode": 200,
        "body": f"Processed {file_key}: {row_count} rows"
    }