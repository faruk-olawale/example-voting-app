# Discover AWS Default VPC (as specified in Capstone requirement)
data "aws_vpc" "default" {
  default = true
}

# Discover Subnets belonging to the Default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Fetch the latest Ubuntu 22.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# Create a dedicated SSH Key Pair for secure access
resource "tls_private_key" "k8s_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "k8s_keypair" {
  key_name   = "${var.cluster_name}-key"
  public_key = tls_private_key.k8s_key.public_key_openssh
}

resource "local_file" "private_key_pem" {
  content         = tls_private_key.k8s_key.private_key_pem
  filename        = "${path.module}/${var.cluster_name}.pem"
  file_permission = "0600"
}

# Security group allowing Kubernetes API, HTTP, NodePorts, and SSH
resource "aws_security_group" "k8s_sg" {
  name        = "${var.cluster_name}-sg"
  description = "Security group for Kubernetes cluster in default VPC"
  vpc_id      = data.aws_vpc.default.id

  # SSH access
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Kubernetes API
  ingress {
    description = "Kubernetes API"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP / HTTPS traffic
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Voting App Ports
  ingress {
    description = "Vote Service"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Result Service"
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Kubernetes NodePort range (30000 - 32767)
  ingress {
    description = "Kubernetes NodePort Services"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-sg"
  }
}

# Provision EC2 Instance running Kubernetes (K3s distribution)
resource "aws_instance" "k8s_node" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = tolist(data.aws_subnets.default.ids)[0]
  vpc_security_group_ids      = [aws_security_group.k8s_sg.id]
  key_name                    = aws_key_pair.k8s_keypair.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    delete_on_termination = true
    tags = {
      Name = "${var.cluster_name}-root-volume"
    }
  }

  # Automated user data script to install and bootstrap certified Kubernetes
  user_data = <<-EOF
              #!/bin/bash
              set -ex

              # Update system packages
              apt-get update -y
              apt-get install -y curl open-iscsi nfs-common

              # Fetch public IP for TLS SAN
              PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

              # Install certified lightweight Kubernetes (K3s) with embedded Traefik ingress
              curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--tls-san $PUBLIC_IP --write-kubeconfig-mode 644" sh -

              # Wait until K3s node is Ready
              until /usr/local/bin/kubectl get nodes | grep -q "Ready"; do
                sleep 5
              done

              # Install Helm inside node
              curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
              EOF

  tags = {
    Name = "${var.cluster_name}-control-plane"
  }
}
