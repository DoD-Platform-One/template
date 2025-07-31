# After the cluster is setup, these scripts will ...
# - Retrieve the Kuberntes config file from S3 and merge it with the local ~/.kube/config
# - Upload the SSH private key to S3

# Retrieves kubeconfig
resource "null_resource" "kubeconfig" {
  triggers = {
    kubeconfig_path = var.kubeconfig_path
  }
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<-EOF
      # Get kubeconfig from storage
      aws s3 cp ${var.kubeconfig_path} ~/.kube/new

      # Merge new config into existing
      export KUBECONFIGBAK=$KUBECONFIG
      export KUBECONFIG=~/.kube/new:~/.kube/config
      # Replace default with cluster name
      sed -ri "s/: default$/: ${var.name}/g" ~/.kube/new
      # Update user only with more info
      sed -ri "s/(user|- name): ${var.name}$/\1: clusterUser_${var.name}/g" ~/.kube/new
      # Do not redirect to ~/.kube/config or you may truncate the results
      kubectl config view --flatten > ~/.kube/merged
      mv -f ~/.kube/merged ~/.kube/config
      chmod 0600 ~/.kube/config

      # Cleanup
      rm -f ~/.kube/new
      export KUBECONFIG=$KUBECONFIGBAK
      unset KUBECONFIGBAK
    EOF
  }
}

# Upload SSH private key
resource "aws_s3_object" "sshkey" {
  key = "ssh-private-key.pem"
  # Get bucket name in middle of s3://<bucket name>/rke2.yaml
  bucket                 = replace(replace(var.kubeconfig_path, "/\\/[^/]*$/", ""), "/^[^/]*\\/\\//", "")
  source                 = pathexpand("${var.private_key_path}/${var.name}.pem")
  server_side_encryption = "aws:kms"
}
