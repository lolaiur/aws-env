data "aws_networkmanager_core_network_policy_document" "policy" {
  core_network_configuration {
    vpn_ecmp_support = false
    asn_ranges       = ["64512-64520"]
    edge_locations {
      location = "us-east-1"
      asn      = 64512
    }
  }

  segments {
    name                          = "main"
    description                   = "main-segment"
    require_attachment_acceptance = false

  }

  segment_actions {
    action     = "share"
    mode       = "attachment-route"
    segment    = "main"
    share_with = ["*"]
  }

  attachment_policies {
    rule_number     = 1
    condition_logic = "or"

    conditions {
      type     = "tag-value"
      operator = "equals"
      key      = "Env"
      value    = "dev"
    }
    action {
      association_method = "constant"
      segment            = "main"
    }
  }
}