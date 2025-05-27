resource "aws_iam_role" "example" {
  name = "clvt-port-role-test01"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "example_policy" {
  name   = "policy-for-clvt-port-role-test01"
  role   = aws_iam_role.example.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "s3:ListAllMyBuckets",
        "ec2:DescribeInstances"
      ],
      Resource = "*"
    }]
  })
}
