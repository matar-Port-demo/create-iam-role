resource "aws_iam_role" "{{ role_name }}_role" {
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

resource "aws_iam_role_policy" "{{ role_name }}_policy" {
  name   = "policy-for-{{ role_name }}"
  role   = aws_iam_role.{{ role_name }}_role.id
  policy = <<POLICY
{{ policy_json }}
POLICY
}
