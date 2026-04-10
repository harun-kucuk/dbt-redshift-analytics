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
