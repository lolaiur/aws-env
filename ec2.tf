resource "aws_instance" "server" {
  for_each = var.ec2

  ami                    = local.amis[each.value.os]
  instance_type          = "t2.micro"
  subnet_id              = module.vpc["${data.aws_region.current.name}-${each.value.vpc}"].intra_subnets[tonumber(each.value.az) - 1]
  iam_instance_profile   = var.deploy_ssm ? aws_iam_instance_profile.ssm[0].name : null
  vpc_security_group_ids = [aws_security_group.ec2["${data.aws_region.current.name}-${each.value.vpc}"].id]
  key_name               = aws_key_pair.ec2_key[each.key].key_name

  user_data = each.value.ud == "Y" ? (each.value.os == "win" ? local.windows_userdata : local.linux_userdata) : null

  tags = {
    Name = each.key
  }
  depends_on = [module.vpc]
}

### SG
resource "aws_security_group" "ec2" {
  for_each    = module.vpc
  name        = "${each.key}-ec2-sg"
  description = "Security group for EC2s in ${each.key}"
  vpc_id      = each.value.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${each.key}-ec2-sg"
  }
}

### Key Pair
resource "aws_key_pair" "ec2_key" {
  for_each   = var.ec2
  key_name   = "${each.key}_key"
  public_key = var.public_key

  tags = {
    Name = "EC2 Key"
  }
}
