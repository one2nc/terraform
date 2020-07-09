resource "aws_iam_role" "bucket_role" {
  name = "${aws_s3_bucket.bucket.id}_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "bucket_iam_profile" {
  name = "${aws_iam_role.bucket_role.name}_profile"
  role = aws_iam_role.bucket_role.name
}

resource "aws_iam_role_policy" "bucket_iam_policy" {
  name = "${aws_iam_role.bucket_role.name}_policy"
  role = aws_iam_role.bucket_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::${var.bucket_name}",
        "arn:aws:s3:::${var.bucket_name}/*"
      ]
    }
  ]
}
EOF
}
