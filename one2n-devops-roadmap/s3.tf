# Terraform state file store in S3
terraform {
    backend "s3" {
        bucket = "one2n-tf"
        region = "ap-south-1"
        key    = "state"
    }
}

# IAM User Creation
# S3 ReadOnly User

data "aws_iam_policy_document" "one2n_read_only" {
  statement {
    effect  = "Allow"
    actions = ["s3:GetObject"]
    resources = [
      "arn:aws:s3:::${var.s3_bucket_name}",
    ]
  }
}

resource "aws_iam_user" "s3_read_only" {
  name = "s3-read-only"

  tags = {
    tag-key = "${var.environment}s3_read_only"
  }
}

resource "aws_iam_access_key" "s3_read_only" {
  user = aws_iam_user.s3_read_only.name
}

resource "aws_iam_user_policy" "s3_read_only" {
  name   = "read-only-policy"
  user   = aws_iam_user.s3_read_only.name
  policy = data.aws_iam_policy_document.one2n_read_only.json

  tags = {
    tag-key = "${var.environment}s3_read_only_policy"
  }
}

# S3 Read Write user

data "aws_iam_policy_document" "read_write" {
  statement {
    sid    = "AllObjectActions"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:ListMultipartUploadParts",
      "s3:AbortMultipartUpload",
    ]
    resources = [
      "arn:aws:s3:::registry-bucket-backend/*",
      "arn:aws:s3:::registry-bucket-backend"
    ]
  }
}

resource "aws_iam_user" "s3_read_write" {
  name = "s3-read-write"

  tags = {
    tag-key = "${var.environment}s3_read_write"
  }
}

resource "aws_iam_access_key" "s3_read_write" {
  user = aws_iam_user.s3_read_write.name
}

resource "aws_iam_user_policy" "s3_read_write" {
  name   = "read-write-policy"
  user   = aws_iam_user.s3_read_write.name
  policy = data.aws_iam_policy_document.read_write.json

  tags = {
    tag-key = "${var.environment}s3_read_write_policy"
  }
}


# S3 Bucket Creation
resource "aws_s3_bucket" "one2n-bucket" {
  bucket = var.s3_bucket_name
  acl    = "private"

  tags = {
    Name = "${var.environment}_one2n_bucket"
  }
}
