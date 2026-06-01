variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "kv-infra-eks-cluster-IaCMdemo"
}

variable "kubernetes_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.31"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnets" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnets" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket (must be globally unique)"
  type        = string
  default     = "kv-infra-s3-bucket-IaCMdemo"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Terraform   = "true"
    Environment = "dev"
    Project     = "infra-eks-s3"
  }
}

variable "additional_admin_role_arn" {
  description = "ARN of additional IAM role to grant admin access to the EKS cluster (e.g., your PowerUser role). Leave empty to skip."
  type        = string
  default     = ""
}

variable "node_count_min" {
  description = "Minimum number of nodes in the EKS node group"
  type        = number
  default     = 3
}

variable "node_count_max" {
  description = "Maximum number of nodes in the EKS node group"
  type        = number
  default     = 3
}

variable "node_count_desired" {
  description = "Desired number of nodes in the EKS node group"
  type        = number
  default     = 3
}
