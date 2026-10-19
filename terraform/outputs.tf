output "default_vpc_id" {
  description = "The ID of the default VPC utilized"
  value       = data.aws_vpc.default.id
}

output "cluster_public_ip" {
  description = "Public IP address of the Kubernetes cluster node"
  value       = aws_instance.k8s_node.public_ip
}

output "ssh_command" {
  description = "SSH connection command using generated private key"
  value       = "ssh -i ${local_file.private_key_pem.filename} ubuntu@${aws_instance.k8s_node.public_ip}"
}

output "kubeconfig_fetch_command" {
  description = "Command to fetch kubeconfig from the remote cluster"
  value       = "scp -i ${local_file.private_key_pem.filename} -o StrictHostKeyChecking=no ubuntu@${aws_instance.k8s_node.public_ip}:/etc/rancher/k3s/k3s.yaml ./kubeconfig && sed -i 's/127.0.0.1/${aws_instance.k8s_node.public_ip}/g' ./kubeconfig"
}

output "vote_url" {
  description = "URL to access the Vote UI via NodePort"
  value       = "http://${aws_instance.k8s_node.public_ip}:31000"
}

output "result_url" {
  description = "URL to access the Result UI via NodePort"
  value       = "http://${aws_instance.k8s_node.public_ip}:31001"
}
