output "endpoint" {
  value = aws_eks_cluster.eks_cluster.endpoint
}

output "cluster_name" {
  value = null_resource.eks_cluster.triggers.name
}

output "cluster_ca" {
  value = aws_eks_cluster.eks_cluster.certificate_authority.0.data
}

output "kubernetes_version" {
  value = aws_eks_cluster.eks_cluster.version
}

variable "eks_version" {
  type    = string
  default = "1.18"
}

variable "eks_node_group_size" {
  type    = string
  default = "t3.micro"
}

resource "null_resource" "eks_cluster" {
  triggers = {
    name = "${local.project_prefix}-cluster"
  }
}

resource "tls_private_key" "private" {
  algorithm = "RSA"
}

resource "aws_key_pair" "private" {
  key_name = "eks_private"
  public_key = "${tls_private_key.private.public_key_openssh}"
}

resource "aws_eks_cluster" "eks_cluster" {
  name     = null_resource.eks_cluster.triggers.name
  role_arn = aws_iam_role.eks_cluster.arn
  version  = var.eks_version
  vpc_config {
    subnet_ids = concat(aws_subnet.public[*].id, aws_subnet.private[*].id)
  }
  tags       = null_resource.tags.triggers
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eks_cluster-AmazonEKSServicePolicy
  ]
}


resource "aws_eks_node_group" "eks_cluster" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "${null_resource.eks_cluster.triggers.name}-node-group"
  node_role_arn   = aws_iam_role.eks_cluster_worker.arn
  subnet_ids      = aws_subnet.private.*.id
  instance_types = [var.eks_node_group_size]
  
  remote_access {
    ec2_ssh_key = aws_key_pair.private.key_name
  }

  scaling_config {
    desired_size = 3
    max_size     = 3
    min_size     = 3
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks_cluster-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks_cluster-AmazonEC2ContainerRegistryReadOnly,
  ]

  tags = {
    Name = "${local.project_prefix}-cluster"
  }
}
