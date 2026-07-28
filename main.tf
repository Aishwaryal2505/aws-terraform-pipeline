resource "aws_s3_bucket" "pipeline_input" {
  bucket = "aish-terraform-pipeline-input"
}

resource "aws_dynamodb_table" "processed_files" {
  name         = "ProcessedFilesTerraform"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "file_id"

  attribute {
    name = "file_id"
    type = "S"
  }
}
resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda-terraform-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "lambda.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_read_only" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "dynamodb_full_access" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "src/lambda_function.py"
  output_path = "lambda_deployment.zip"
}

resource "aws_lambda_function" "csv_processor" {
  function_name    = "process-csv-pipeline-terraform"
  runtime          = "python3.12"
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "lambda_function.lambda_handler"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout          = 30
  memory_size      = 128
}
resource "aws_lambda_permission" "allow_s3_invoke" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.csv_processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.pipeline_input.arn
}

resource "aws_s3_bucket_notification" "csv_trigger" {
  bucket = aws_s3_bucket.pipeline_input.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.csv_processor.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".csv"
  }

  depends_on = [aws_lambda_permission.allow_s3_invoke]
}