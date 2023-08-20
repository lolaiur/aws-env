resource "aws_ssm_association" "example" {
  count = var.deploy_ssm ? length(aws_instance.server) : 0

  name = "AWS-ConfigureAWSPackage"
  targets {
    key    = "InstanceIds"
    values = [element(aws_instance.server.*.id, count.index)]
  }

  parameters = {
    action  = "Install"
    name    = "AmazonCloudWatchAgent"
    version = "latest"
  }

  schedule_expression = "rate(30 minutes)"
}

resource "aws_iam_role" "ssm_role" {
  count = var.deploy_ssm ? 1 : 0
  name  = "ssm_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Effect = "Allow"
      },
    ]
  })
}

resource "aws_iam_role_policy" "ssm_policy" {
  count = var.deploy_ssm ? 1 : 0
  name  = "ssm_policy"
  role  = aws_iam_role.ssm_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "*"
          #"ssm:UpdateInstanceInformation",
          #"ssmmessages:CreateControlChannel",
          #"ssmmessages:CreateDataChannel",
          #"ssmmessages:OpenControlChannel",
          #"ssmmessages:OpenDataChannel"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = aws_kms_key.ssm_key[0].arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_role_policy_attachment" {
  count      = var.deploy_ssm ? 1 : 0
  role       = aws_iam_role.ssm_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm" {
  count = var.deploy_ssm ? 1 : 0
  name  = aws_iam_role.ssm_role[0].name
  role  = aws_iam_role.ssm_role[0].name
}

resource "aws_ssm_document" "ssm_document" {
  count           = var.deploy_ssm ? 1 : 0
  name            = "SSM-SessionManagerRunShell"
  document_type   = "Session"
  document_format = "JSON"

  content = <<DOC
{
  "schemaVersion": "1.0",
  "description": "Document to hold regional settings for Session Manager",
  "sessionType": "Standard_Stream",
  "inputs": {
    "s3BucketName": "",
    "s3KeyPrefix": "",
    "s3EncryptionEnabled": false,
    "cloudWatchLogGroupName": "",
    "cloudWatchEncryptionEnabled": false,
    "kmsKeyId": ""
  }
}
DOC
}

resource "aws_ssm_service_setting" "default_host_management" {
  count         = var.deploy_ssm ? 1 : 0
  setting_id    = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:servicesetting/ssm/managed-instance/default-ec2-instance-management-role"
  setting_value = aws_iam_role.ssm_role[0].name
}

resource "aws_kms_key" "ssm_key" {
  count       = var.deploy_ssm ? 1 : 0
  description = "KMS key for SSM"
  policy      = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "key-default-1",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    }
  ]
}
POLICY
}