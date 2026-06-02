# ECS Fargate - Provisions in ~3-5 minutes (much faster than EKS)

terraform {
  required_version = ">= 1.9.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.82"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# VPC (simple, 2 subnets)
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "ecs-demo-vpc"
  }
}

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "ecs-public-subnet-1"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "ecs-public-subnet-2"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "ecs-demo-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "ecs-public-rt"
  }
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "demo-cluster"

  tags = {
    Name = "demo-ecs-cluster"
  }
}

# Security Group
resource "aws_security_group" "ecs_tasks" {
  name        = "ecs-tasks-sg"
  description = "Allow inbound traffic to ECS tasks"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecs-tasks-sg"
  }
}

# IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# S3 Bucket
resource "aws_s3_bucket" "demo" {
  bucket        = "ecs-demo-bucket-${random_id.bucket_suffix.hex}"
  force_destroy = true

  tags = {
    Name = "ecs-demo-bucket"
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Outputs
output "cluster_name" {
  value       = aws_ecs_cluster.main.name
  description = "ECS Cluster name"
}

output "vpc_id" {
  value       = aws_vpc.main.id
  description = "VPC ID"
}

output "subnet_ids" {
  value       = [aws_subnet.public_1.id, aws_subnet.public_2.id]
  description = "Subnet IDs for deploying tasks"
}

output "security_group_id" {
  value       = aws_security_group.ecs_tasks.id
  description = "Security group for ECS tasks"
}

output "s3_bucket_name" {
  value       = aws_s3_bucket.demo.id
  description = "S3 bucket name"
}

output "deploy_sample_app" {
  value = <<-EOT
    # Deploy a sample nginx app:
    aws ecs run-task \
      --cluster ${aws_ecs_cluster.main.name} \
      --launch-type FARGATE \
      --task-definition arn:aws:ecs:us-east-1:<account-id>:task-definition/nginx:1 \
      --network-configuration "awsvpcConfiguration={subnets=[${aws_subnet.public_1.id},${aws_subnet.public_2.id}],securityGroups=[${aws_security_group.ecs_tasks.id}],assignPublicIp=ENABLED}"
  EOT
  description = "Command to deploy sample app"
}
