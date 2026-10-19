variable "aws_region" {
  description = "AWS region for the Kubernetes infrastructure"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name identifier for the Kubernetes cluster"
  type        = string
  default     = "voting-app-k8s"
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod, capstone)"
  type        = string
  default     = "capstone"
}

variable "instance_type" {
  description = "EC2 instance size for the Kubernetes node"
  type        = string
  default     = "t3.medium"
}
