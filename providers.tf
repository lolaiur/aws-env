terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.13.1"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.1"
    }
    #fortios = {
    #  source  = "fortinetdev/fortios"
    #  version = "1.17.0"
    #}
  }
}

