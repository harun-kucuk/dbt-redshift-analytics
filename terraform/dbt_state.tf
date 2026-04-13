resource "aws_s3_bucket" "dbt_state" {
  bucket = "${var.workgroup_name}-dbt-state-${data.aws_caller_identity.current.account_id}"

  tags = {
    Project = "dbt-redshift-analytics"
  }
}

resource "aws_s3_bucket_versioning" "dbt_state" {
  bucket = aws_s3_bucket.dbt_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "dbt_state" {
  bucket = aws_s3_bucket.dbt_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "dbt_state" {
  bucket                  = aws_s3_bucket.dbt_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
