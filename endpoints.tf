resource "aws_vpc_endpoint" "ec2messages" {
  for_each            = var.deploy_ep ? module.vpc : {}
  vpc_id              = each.value.vpc_id
  service_name        = "com.amazonaws.${join("-", slice(split("-", each.key), 0, 3))}.ec2messages"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.endpoint_sg[each.key].id]
  subnet_ids          = tolist(each.value.intra_subnets)
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ssm" {
  for_each            = var.deploy_ep ? module.vpc : {}
  vpc_id              = each.value.vpc_id
  service_name        = "com.amazonaws.${join("-", slice(split("-", each.key), 0, 3))}.ssm"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.endpoint_sg[each.key].id]
  subnet_ids          = tolist(each.value.intra_subnets)
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ssmmessages" {
  for_each            = var.deploy_ep ? module.vpc : {}
  vpc_id              = each.value.vpc_id
  service_name        = "com.amazonaws.${join("-", slice(split("-", each.key), 0, 3))}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.endpoint_sg[each.key].id]
  subnet_ids          = tolist(each.value.intra_subnets)
  private_dns_enabled = true
}


### EP SG Creation
resource "aws_security_group" "endpoint_sg" {
  for_each    = var.deploy_ep ? module.vpc : {}
  name        = "${each.key}-endpoint-sg"
  description = "Security group for VPC endpoints in ${each.key}"
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
    Name = "${each.key}-endpoint-sg"
  }
}
