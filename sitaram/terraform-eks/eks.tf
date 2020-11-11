output "endpoint" {
  value = aws_eks_cluster.eks_cluster.endpoint
}

output "cluster_name" {
  value = null_resource.eks_cluster.triggers.name
}

variable "eks_version" {
  type    = string
  default = "1.18"
}

resource "null_resource" "eks_cluster" {
  triggers = {
    name = "${local.project_prefix}-cluster"
  }

}

resource "aws_eks_cluster" "eks_cluster" {
  name     = null_resource.eks_cluster.triggers.name
  role_arn = aws_iam_role.eks_iam.arn
  version  = var.eks_version
  vpc_config {
    subnet_ids = concat(aws_subnet.public[*].id, aws_subnet.private[*].id)
  }
  tags       = null_resource.tags.triggers
  depends_on = [aws_iam_role_policy_attachment.eks-iam-AmazonEKSClusterPolicy]
}