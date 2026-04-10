# --- Data sources: default VPC & subnets ---

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# --- Security group: public endpoint, restricted by CIDR allowlist ---

resource "aws_security_group" "redshift_serverless" {
  name        = "${var.workgroup_name}-redshift-sg"
  description = "Allow Redshift Serverless access"
  vpc_id      = data.aws_vpc.default.id

  dynamic "ingress" {
    for_each = toset(var.allowed_cidr_blocks)
    content {
      description = "Redshift port - allowlisted client access"
      from_port   = 5439
      to_port     = 5439
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- Redshift Serverless namespace (holds users/databases) ---

resource "aws_redshiftserverless_namespace" "this" {
  namespace_name      = var.namespace_name
  db_name             = var.db_name
  admin_username      = var.admin_username
  admin_user_password = var.admin_password

  tags = {
    Project = "dbt-redshift-analytics"
  }
}

# --- Redshift Serverless workgroup (compute layer) ---

resource "aws_redshiftserverless_workgroup" "this" {
  namespace_name = aws_redshiftserverless_namespace.this.namespace_name
  workgroup_name = var.workgroup_name

  # Minimum base capacity (8 RPU) keeps costs low for a portfolio project.
  # Redshift Serverless auto-scales above this as needed.
  base_capacity = 8

  subnet_ids         = data.aws_subnets.default.ids
  security_group_ids = [aws_security_group.redshift_serverless.id]

  # Keep the endpoint public for local development and CI, but limit network
  # access to the configured CIDR allowlist above.
  publicly_accessible = true

  tags = {
    Project = "dbt-redshift-analytics"
  }
}
