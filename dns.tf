
### Creates DNS solution within AWS and registers EC2 A Records to resolve within DNS

resource "aws_route53_zone" "private_zone" {
  count = var.deploy_dns ? 1 : 0
  name  = "aiur.com"
  vpc {
    vpc_id = module.vpcVPN[0].vpc_id
  }

  tags = {
    Name = "private-zone"
  }

  lifecycle {
    ignore_changes = [vpc]
  }
}

resource "aws_route53_zone_association" "this" {
  for_each = var.deploy_dns ? { for key, value in module.vpc : key => value.vpc_id } : {}
  zone_id  = aws_route53_zone.private_zone[0].id
  vpc_id   = each.value
}

resource "aws_route53_record" "this" {
  for_each = var.deploy_dns ? var.ec2 : {}
  zone_id  = aws_route53_zone.private_zone[0].id
  name     = "${each.key}.aiur.com"
  type     = "A"
  records  = [aws_instance.server[each.key].private_ip]
  ttl      = 300
}