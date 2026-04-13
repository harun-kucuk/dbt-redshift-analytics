output "namespace_id" {
  description = "Redshift Serverless namespace ID"
  value       = aws_redshiftserverless_namespace.this.id
}

output "workgroup_endpoint" {
  description = "Redshift Serverless JDBC endpoint (host:port/db)"
  value       = "${aws_redshiftserverless_workgroup.this.endpoint[0].address}:${aws_redshiftserverless_workgroup.this.endpoint[0].port}/${var.db_name}"
}

output "workgroup_host" {
  description = "Redshift Serverless host (use in dbt profiles.yml)"
  value       = aws_redshiftserverless_workgroup.this.endpoint[0].address
}

output "workgroup_port" {
  description = "Redshift Serverless port"
  value       = aws_redshiftserverless_workgroup.this.endpoint[0].port
}

output "raw_ingest_bucket" {
  description = "S3 bucket for raw data ingestion"
  value       = aws_s3_bucket.raw_ingest.bucket
}

output "raw_ingest_s3_prefix" {
  description = "S3 prefix monitored by the sales_feed auto copy job"
  value       = "s3://${aws_s3_bucket.raw_ingest.bucket}/sales-feed/"
}

output "dbt_state_bucket" {
  description = "S3 bucket that stores dbt state artifacts such as the latest manifest.json"
  value       = aws_s3_bucket.dbt_state.bucket
}

output "dbt_state_manifest_s3_uri" {
  description = "S3 URI for the latest production dbt manifest"
  value       = "s3://${aws_s3_bucket.dbt_state.bucket}/artifacts/prod/manifest.json"
}
