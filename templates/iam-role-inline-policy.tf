resource "aws_iam_role" "example" {
  name = "{{ role_name }}"
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
  name   = "policy-for-{{ role_name }}"
  role   = aws_iam_role.example.id
  policy = <<POLICY
{{ policy_json }}
POLICY
}
