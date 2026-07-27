# AWS Serverless Pipeline (Terraform / Infrastructure as Code)

The same event-driven S3-to-Lambda-to-DynamoDB pipeline as my boto3-based version,
rebuilt entirely using Terraform - declaring the desired infrastructure state and
letting Terraform handle creation order, dependency resolution, and drift detection.

## Why this exists alongside the boto3 version
Building the identical pipeline two ways - imperatively with boto3 and declaratively
with Terraform - demonstrates both approaches:
- boto3: fine-grained programmatic control over each AWS API call
- Terraform: preview-before-apply safety (`terraform plan`), automatic dependency
  ordering, and a maintainable, versioned infrastructure definition

## Architecture
All resources - S3 bucket, DynamoDB table, IAM role + policies, Lambda function,
and the S3 event trigger - are defined in `main.tf` and provisioned with a single
`terraform apply`.

## Key Terraform concepts demonstrated
- Provider configuration and version constraints (`provider.tf`)
- Resource references for automatic dependency ordering (e.g. IAM role -> policy attachments)
- The `archive_file` data source for packaging Lambda code without custom zip logic
- `source_code_hash` for automatic redeploy-on-change detection
- Explicit `depends_on` where dependency isn't inferable from references alone
  (S3 invoke permission must exist before the S3 notification trigger)
- Least-privilege IAM: Lambda's role has S3 **read-only** access

## Running locally
```bash
# Configure AWS credentials in ~/.aws/credentials first
terraform init
terraform plan
terraform apply
```

## Tearing down
```bash
terraform destroy
```