output "bucket_arn" {
  value = aws_s3_bucket.bucket.arn
}


variable "bucket_name" {
  type = string
}

resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket_name
  acl    = "private"
}
