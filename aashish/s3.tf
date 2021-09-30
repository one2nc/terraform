resource "aws_s3_bucket" "main_bucket" {
  bucket = "in.ashnehete.test"
}

resource "aws_iam_user" "s3_read" {
  name = "s3_read"
}

resource "aws_iam_user_policy_attachment" "s3_read" {
  user       = aws_iam_user.s3_read.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_user" "s3_read_write" {
  name = "s3_read_write"
}

resource "aws_iam_user_policy_attachment" "s3_read_write" {
  user       = aws_iam_user.s3_read_write.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}
