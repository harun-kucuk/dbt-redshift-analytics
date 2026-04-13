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
