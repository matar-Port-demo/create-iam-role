resource "aws_iam_role" "example" {
  name = "clvt-port-role-test04"

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
  name   = "policy-for-clvt-port-role-test04"
  role   = aws_iam_role.example.id
  policy = <<POLICY
"{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"EC2Access\",\"Effect\":\"Allow\",\"Action\":[\"ec2:Describe*\",\"ec2:StartInstances\",\"ec2:StopInstances\",\"ec2:RebootInstances\"],\"Resource\":\"*\"},{\"Sid\":\"S3ReadAccess\",\"Effect\":\"Allow\",\"Action\":[\"s3:ListAllMyBuckets\",\"s3:ListBucket\",\"s3:GetObject\"],\"Resource\":\"*\"},{\"Sid\":\"CloudWatchReadOnly\",\"Effect\":\"Allow\",\"Action\":[\"cloudwatch:GetMetricData\",\"cloudwatch:ListMetrics\",\"cloudwatch:GetMetricStatistics\",\"logs:DescribeLogGroups\",\"logs:GetLogEvents\",\"logs:DescribeLogStreams\"],\"Resource\":\"*\"},{\"Sid\":\"IAMReadOnly\",\"Effect\":\"Allow\",\"Action\":[\"iam:ListUsers\",\"iam:GetUser\",\"iam:ListRoles\",\"iam:GetRole\"],\"Resource\":\"*\"}]}"
POLICY
}
