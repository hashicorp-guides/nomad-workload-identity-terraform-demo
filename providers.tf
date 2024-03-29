terraform {
  required_providers {
    consul = {
      source  = "hashicorp/consul"
      version = "~> 2.18"
    }
    nomad = {
      source  = "hashicorp/nomad"
      version = "~>2.0.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.21"
    }
  }
}

provider "consul" {
  address = "http://127.0.0.1:8500"
}

provider "nomad" {
  address = "http://127.0.0.1:4646"
}

provider "vault" {
  address = "http://127.0.0.1:8200"

  # Vault Enterprise: apply configuration to a namespace.
  # namespace = "prod"
}
