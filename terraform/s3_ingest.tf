data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

# --- S3 bucket for raw data ingestion ---

resource "aws_s3_bucket" "raw_ingest" {
  bucket = "${var.workgroup_name}-raw-ingest-${data.aws_caller_identity.current.account_id}"

  tags = {
    Project = "dbt-redshift-analytics"
  }
}

resource "aws_s3_bucket_versioning" "raw_ingest" {
  bucket = aws_s3_bucket.raw_ingest.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "raw_ingest" {
  bucket = aws_s3_bucket.raw_ingest.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "raw_ingest" {
  bucket                  = aws_s3_bucket.raw_ingest.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Redshift manages the bucket notification once the S3 event integration exists.
resource "aws_s3_bucket_policy" "raw_ingest_redshift_integration" {
  bucket = aws_s3_bucket.raw_ingest.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowRedshiftToManageBucketNotifications"
        Effect = "Allow"
        Principal = {
          Service = "redshift.amazonaws.com"
        }
        Action = [
          "s3:GetBucketNotification",
          "s3:PutBucketNotification",
          "s3:GetBucketLocation",
        ]
        Resource = aws_s3_bucket.raw_ingest.arn
        Condition = {
          ArnLike = {
            "aws:SourceArn" = "arn:${data.aws_partition.current.partition}:redshift:${var.aws_region}:${data.aws_caller_identity.current.account_id}:integration:*"
          }
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
    ]
  })
}

# --- IAM role allowing Redshift to read from the ingest bucket ---

resource "aws_iam_role" "redshift_s3_ingest" {
  name = "${var.workgroup_name}-redshift-s3-ingest"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "redshift.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Project = "dbt-redshift-analytics"
  }
}

resource "aws_iam_role_policy" "redshift_s3_ingest" {
  name = "${var.workgroup_name}-redshift-s3-ingest"
  role = aws_iam_role.redshift_s3_ingest.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:ListBucket",
        "s3:GetBucketLocation",
      ]
      Resource = [
        aws_s3_bucket.raw_ingest.arn,
        "${aws_s3_bucket.raw_ingest.arn}/*",
      ]
    }]
  })
}

# Redshift also needs a resource policy on the target namespace before
# aws redshift create-integration can succeed.
resource "null_resource" "redshift_s3_event_integration_prereqs" {
  triggers = {
    bucket_name  = aws_s3_bucket.raw_ingest.bucket
    namespace    = var.namespace_name
    account_id   = data.aws_caller_identity.current.account_id
    iam_role_arn = aws_iam_role.redshift_s3_ingest.arn
    aws_region   = var.aws_region
    partition    = data.aws_partition.current.partition
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -euo pipefail

      REGION='${var.aws_region}'
      BUCKET='${aws_s3_bucket.raw_ingest.bucket}'
      ACCOUNT='${data.aws_caller_identity.current.account_id}'
      NAMESPACE='${var.namespace_name}'
      PARTITION='${data.aws_partition.current.partition}'
      CALLER_ARN=$(aws sts get-caller-identity --region "$REGION" --query 'Arn' --output text)
      TARGET_ARN=$(aws redshift-serverless get-namespace \
        --namespace-name "$NAMESPACE" \
        --region "$REGION" \
        --query 'namespace.namespaceArn' \
        --output text)

      POLICY=$(cat <<JSON
      {
        "Version": "2012-10-17",
        "Statement": [
          {
            "Effect": "Allow",
            "Principal": {
              "Service": "redshift.amazonaws.com"
            },
            "Action": "redshift:AuthorizeInboundIntegration",
            "Resource": "$TARGET_ARN",
            "Condition": {
              "StringEquals": {
                "aws:SourceArn": "arn:${data.aws_partition.current.partition}:s3:::$${BUCKET}",
                "aws:SourceAccount": "$ACCOUNT"
              }
            }
          },
          {
            "Effect": "Allow",
            "Principal": {
              "AWS": "$CALLER_ARN"
            },
            "Action": "redshift:CreateInboundIntegration",
            "Resource": "$TARGET_ARN",
            "Condition": {
              "StringEquals": {
                "aws:SourceArn": "arn:${data.aws_partition.current.partition}:s3:::$${BUCKET}",
                "aws:SourceAccount": "$ACCOUNT"
              }
            }
          }
        ]
      }
      JSON
      )

      aws redshift put-resource-policy \
        --region "$REGION" \
        --resource-arn "$TARGET_ARN" \
        --policy "$POLICY" >/dev/null
    EOT
  }

  depends_on = [
    aws_redshiftserverless_namespace.this,
    aws_iam_role_policy.redshift_s3_ingest,
    aws_s3_bucket_policy.raw_ingest_redshift_integration,
  ]
}

# --- Target table: raw.sales_feed ---
# Columns mirror the TICKIT sales schema plus a loaded_at audit column.

resource "null_resource" "redshift_table_sales_feed" {
  triggers = {
    schema_table = "raw.sales_feed"
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -euo pipefail

      wait_stmt() {
        local id=$1
        while true; do
          S=$(aws redshift-data describe-statement --id "$id" --region ${var.aws_region} --query "Status" --output text)
          [ "$S" = "FINISHED" ] && return 0
          if [ "$S" = "FAILED" ]; then
            ERR=$(aws redshift-data describe-statement --id "$id" --region ${var.aws_region} --query "Error" --output text)
            echo "$ERR"
            return 1
          fi
          sleep 2
        done
      }

      echo "Creating schema raw (idempotent)..."
      SCHEMA_ID=$(aws redshift-data execute-statement \
        --workgroup-name ${var.workgroup_name} \
        --database ${var.db_name} \
        --region ${var.aws_region} \
        --sql "CREATE SCHEMA IF NOT EXISTS \"raw\"" \
        --query "Id" --output text)
      wait_stmt "$SCHEMA_ID" || { echo "Schema creation failed"; exit 1; }

      echo "Creating table raw.sales_feed..."
      STMT_ID=$(aws redshift-data execute-statement \
        --workgroup-name ${var.workgroup_name} \
        --database ${var.db_name} \
        --region ${var.aws_region} \
        --sql "CREATE TABLE \"raw\".sales_feed (sale_id INTEGER, listing_id INTEGER, seller_id INTEGER, buyer_id INTEGER, event_id INTEGER, date_id INTEGER, qty_sold SMALLINT, price_paid DECIMAL(8,2), commission DECIMAL(8,2), sale_at TIMESTAMP, loaded_at TIMESTAMP DEFAULT GETDATE())" \
        --query "Id" --output text)

      ERR=$(wait_stmt "$STMT_ID" 2>&1) && { echo "Table raw.sales_feed ready."; } || {
        echo "$ERR" | grep -qi "already exists" && { echo "Table already exists, continuing."; } || { echo "Table creation failed: $ERR"; exit 1; }
      }
    EOT
  }

  depends_on = [
    null_resource.redshift_schemas,
    aws_redshiftserverless_workgroup.this,
  ]
}

# --- Auto copy job ---
# Redshift owns the S3 event integration and the bucket notification.
# Terraform only ensures the prerequisites exist and then creates the COPY JOB.

resource "null_resource" "redshift_autocopy_job" {
  triggers = {
    bucket           = aws_s3_bucket.raw_ingest.bucket
    iam_arn          = aws_iam_role.redshift_s3_ingest.arn
    integration_name = "${var.workgroup_name}-s3-sales-feed"
    copy_sql_hash = sha256(join("\n", [
      "COPY \"raw\".sales_feed (sale_id, listing_id, seller_id, buyer_id, event_id, date_id, qty_sold, price_paid, commission, sale_at)",
      "FROM 's3://${aws_s3_bucket.raw_ingest.bucket}/sales-feed/'",
      "IAM_ROLE '${aws_iam_role.redshift_s3_ingest.arn}'",
      "FORMAT AS CSV",
      "IGNOREHEADER 1",
      "DELIMITER ','",
      "JOB CREATE sales_feed_copy",
      "AUTO ON",
    ]))
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -euo pipefail

      ROLE='${aws_iam_role.redshift_s3_ingest.arn}'
      BUCKET='${aws_s3_bucket.raw_ingest.bucket}'
      WG='${var.workgroup_name}'
      DB='${var.db_name}'
      REGION='${var.aws_region}'
      NAMESPACE='${var.namespace_name}'
      INTEGRATION_NAME='${var.workgroup_name}-s3-sales-feed'

      wait_stmt() {
        local id=$1
        while true; do
          S=$(aws redshift-data describe-statement --id "$id" --region "$REGION" --query "Status" --output text)
          [ "$S" = "FINISHED" ] && return 0
          if [ "$S" = "FAILED" ]; then
            echo "$(aws redshift-data describe-statement --id "$id" --region "$REGION" --query "Error" --output text)"
            return 1
          fi
          sleep 2
        done
      }

      TARGET_ARN=$(aws redshift-serverless get-namespace \
        --namespace-name "$NAMESPACE" \
        --region "$REGION" \
        --query 'namespace.namespaceArn' \
        --output text)

      EXISTING_ARN=$(aws redshift describe-integrations \
        --region "$REGION" \
        --query "Integrations[?IntegrationName=='$INTEGRATION_NAME'].IntegrationArn | [0]" \
        --output text)

      if [ "$EXISTING_ARN" = "None" ] || [ -z "$EXISTING_ARN" ]; then
        echo "Creating S3 event integration..."
        INTEGRATION_ARN=$(aws redshift create-integration \
          --integration-name "$INTEGRATION_NAME" \
          --source-arn "arn:${data.aws_partition.current.partition}:s3:::$BUCKET" \
          --target-arn "$TARGET_ARN" \
          --region "$REGION" \
          --query "IntegrationArn" \
          --output text)
      else
        INTEGRATION_ARN="$EXISTING_ARN"
        echo "S3 event integration already exists: $INTEGRATION_ARN"
      fi

      echo "Waiting for integration to become active..."
      while true; do
        STATUS=$(aws redshift describe-integrations \
          --region "$REGION" \
          --query "Integrations[?IntegrationArn=='$INTEGRATION_ARN'].Status | [0]" \
          --output text | tr '[:upper:]' '[:lower:]')
        echo "  status: $STATUS"
        [ "$STATUS" = "active" ] && break
        [ "$STATUS" = "failed" ] || [ "$STATUS" = "inactive" ] && { echo "Integration is not active"; exit 1; }
        sleep 5
      done

      COPY_SQL=$(cat <<SQL
      COPY "raw".sales_feed (sale_id, listing_id, seller_id, buyer_id, event_id, date_id, qty_sold, price_paid, commission, sale_at)
      FROM 's3://$BUCKET/sales-feed/'
      IAM_ROLE '$ROLE'
      FORMAT AS CSV
      IGNOREHEADER 1
      DELIMITER ','
      JOB CREATE sales_feed_copy
      AUTO ON
      SQL
      )

      CURRENT_COPY_SQL=$(aws redshift-data execute-statement \
        --workgroup-name "$WG" \
        --database "$DB" \
        --region "$REGION" \
        --sql "SELECT copy_query FROM sys_copy_job WHERE job_name = 'sales_feed_copy'" \
        --query "Id" \
        --output text)

      if wait_stmt "$CURRENT_COPY_SQL" >/dev/null 2>&1; then
        EXISTING_SQL=$(aws redshift-data get-statement-result \
          --id "$CURRENT_COPY_SQL" \
          --region "$REGION" \
          --query "Records[0][0].stringValue" \
          --output text)
        if [ "$EXISTING_SQL" != "None" ] && [ -n "$EXISTING_SQL" ] && [ "$EXISTING_SQL" != "$COPY_SQL" ]; then
          echo "COPY JOB definition changed; dropping existing job..."
          DROP_ID=$(aws redshift-data execute-statement \
            --workgroup-name "$WG" \
            --database "$DB" \
            --region "$REGION" \
            --sql "COPY JOB DROP sales_feed_copy" \
            --query "Id" \
            --output text)
          wait_stmt "$DROP_ID" || { echo "Failed to drop existing COPY JOB"; exit 1; }
        fi
      fi

      echo "Creating COPY JOB..."
      STMT_ID=$(aws redshift-data execute-statement \
        --workgroup-name "$WG" \
        --database "$DB" \
        --region "$REGION" \
        --sql "$COPY_SQL" \
        --query "Id" \
        --output text)

      ERR=$(wait_stmt "$STMT_ID" 2>&1) && echo "COPY JOB created." || {
        echo "$ERR" | grep -qi "already exists" && echo "COPY JOB already exists, continuing." \
          || { echo "COPY JOB creation failed: $ERR"; exit 1; }
      }

      echo "Auto-copy is configured for s3://$BUCKET/sales-feed/."
      echo "Useful checks:"
      echo "  SELECT * FROM SYS_COPY_JOB;"
      echo "  SELECT * FROM SYS_COPY_JOB_DETAIL WHERE job_name = 'sales_feed_copy';"
      echo "  SELECT * FROM SVV_COPY_JOB_INTEGRATIONS;"
    EOT
  }

  depends_on = [
    null_resource.redshift_table_sales_feed,
    null_resource.redshift_s3_event_integration_prereqs,
  ]
}
