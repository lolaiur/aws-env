module "cloudwan" {

  count = var.create_cgw ? 1 : 0

  source  = "aws-ia/cloudwan/aws"
  version = "~>2"

  global_network = {
    create      = var.create_cgw
    description = "Global Network - AWS CloudWAN Module"
  }
  core_network = {
    description     = "Core Network - AWS CloudWAN Module"
    policy_document = data.aws_networkmanager_core_network_policy_document.policy.json
  }


  tags = {
    Name = "create-global-network"
  }
}