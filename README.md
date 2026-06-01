# EKS Cluster with S3 Bucket Infrastructure

This Terraform project provisions an AWS EKS cluster with 3 t3.micro nodes and an S3 bucket.

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.9.0
- kubectl (for cluster management)

## Resources Created

- **VPC**: Custom VPC with public and private subnets across 3 availability zones
- **EKS Cluster**: Managed Kubernetes cluster (version 1.31)
- **Node Group**: 3 t3.micro EC2 instances in a managed node group
- **S3 Bucket**: Encrypted bucket with versioning enabled and public access blocked
- **Supporting Resources**: NAT Gateway, Internet Gateway, Route Tables, Security Groups

## Usage

### 1. Initialize Terraform

```bash
cd infra-eks-s3
terraform init
```

### 2. Review the Plan

```bash
terraform plan
```

### 3. Configure Variables (Optional but Recommended)

Create a `terraform.tfvars` file to customize your deployment:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and update the values, especially:
- `additional_admin_role_arn`: Add your IAM role ARN to grant cluster admin access
- `s3_bucket_name`: Must be globally unique

**To find your IAM role ARN:**

```bash
aws sts get-caller-identity
# Use the role ARN from the output
```

### 4. Apply Configuration

```bash
terraform apply
```

Or specify variables directly:

```bash
terraform apply \
  -var="s3_bucket_name=your-unique-bucket-name" \
  -var="additional_admin_role_arn=arn:aws:iam::123456789012:role/YourRole"
```

### 5. Configure kubectl

After the cluster is created, configure kubectl to access it:

```bash
aws eks update-kubeconfig --region us-east-1 --name kv-infra-eks-cluster-IaCMdemo
```

### 6. Verify Cluster

```bash
kubectl get nodes
kubectl get pods -A
```

## Customization

You can customize the deployment by modifying variables in `variables.tf` or by passing them during apply:

```bash
terraform apply \
  -var="aws_region=us-east-1" \
  -var="cluster_name=my-eks-cluster" \
  -var="kubernetes_version=1.31" \
  -var="s3_bucket_name=my-unique-bucket-name"
```

## Outputs

The configuration provides several outputs including:
- EKS cluster endpoint and certificate
- S3 bucket ID and ARN
- VPC ID
- kubectl configuration command

View outputs:

```bash
terraform output
```

## Cost Considerations

- **EKS Cluster**: ~$0.10/hour for the control plane
- **EC2 t3.micro**: ~$0.0104/hour per instance × 3 = ~$0.03/hour
- **NAT Gateway**: ~$0.045/hour + data transfer costs
- **S3 Bucket**: Pay for storage and requests

Total estimated cost: ~$0.18/hour or ~$130/month

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

## IAM Access Management

This configuration uses **EKS Access Entries** (the modern approach) to manage cluster access. 

### Granting Additional Users/Roles Access

To grant additional IAM roles or users admin access to the cluster:

1. Set the `additional_admin_role_arn` variable to the IAM role ARN
2. Apply the configuration

The role will automatically be granted cluster admin permissions via the `AmazonEKSClusterAdminPolicy`.

### Finding Your Role ARN

```bash
aws sts get-caller-identity
# Copy the role ARN from "Arn" field
```

## Security Features

- Private subnets for worker nodes
- Public access blocking for S3 bucket
- S3 bucket encryption enabled
- S3 versioning enabled
- VPC with proper subnet tagging for EKS
- EKS Access Entries for fine-grained IAM access control

## Notes

- The cluster uses a single NAT Gateway to reduce costs (suitable for dev/test)
- Node group uses ON_DEMAND capacity type
- Cluster endpoint has public access enabled (adjust for production use)
