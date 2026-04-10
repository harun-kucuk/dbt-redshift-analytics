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

# --- Security group: allow Redshift port publicly (password + SSL enforced) ---

resource "aws_security_group" "redshift_serverless" {
  name        = "${var.workgroup_name}-redshift-sg"
  description = "Allow Redshift Serverless access"
  vpc_id      = data.aws_vpc.default.id

  # Ignore manual ingress rules added outside Terraform (e.g. your laptop IP)
  lifecycle {
    ignore_changes = [ingress]
  }

  ingress {
    description = "Redshift port - public (CI/CD + local access)"
    from_port   = 5439
    to_port     = 5439
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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

  # Make the endpoint publicly accessible so dbt can reach it from your laptop.
  publicly_accessible = true

  tags = {
    Project = "dbt-redshift-analytics"
  }
}
