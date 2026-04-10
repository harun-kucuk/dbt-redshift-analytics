locals {
  schemas_csv = csvdecode(file("${path.module}/schemas.csv"))
  schemas     = { for row in local.schemas_csv : row.name => row }
}

resource "null_resource" "redshift_schemas" {
  for_each = local.schemas

  triggers = {
    schema   = each.value.name
    database = each.value.database
  }

  provisioner "local-exec" {
    command = <<-EOT
      aws redshift-data execute-statement \
        --workgroup-name ${var.workgroup_name} \
        --database ${each.value.database} \
        --sql "CREATE SCHEMA IF NOT EXISTS ${each.value.name}" \
        --region ${var.aws_region}
    EOT
  }

  depends_on = [aws_redshiftserverless_workgroup.this]
}
