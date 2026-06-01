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

### 3. Apply Configuration

**Important**: Before applying, update the `s3_bucket_name` variable in `variables.tf` or pass it via command line, as S3 bucket names must be globally unique.

```bash
terraform apply -var="s3_bucket_name=your-unique-bucket-name"
```

### 4. Configure kubectl

After the cluster is created, configure kubectl to access it:

```bash
aws eks update-kubeconfig --region us-west-2 --name infra-eks-cluster
```

### 5. Verify Cluster

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

## Security Features

- Private subnets for worker nodes
- Public access blocking for S3 bucket
- S3 bucket encryption enabled
- S3 versioning enabled
- VPC with proper subnet tagging for EKS

## Notes

- The cluster uses a single NAT Gateway to reduce costs (suitable for dev/test)
- Node group uses ON_DEMAND capacity type
- Cluster endpoint has public access enabled (adjust for production use)
