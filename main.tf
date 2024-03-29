# Setup Consul and Vault JWT authentication for Nomad.
module "vault_setup" {
  source  = "hashicorp-modules/nomad-setup/vault"
  version = "1.1.0"

  # nomad_jwks_url should be reachable by all Consul agents and resolve to
  # multiple Nomad agents for high availability.
  #
  # In a production environment this URL should be handled by an external
  # component, such as a load balancer, a reverse proxy, or a DNS entry with
  # multiple IPs.
  nomad_jwks_url = "http://localhost:4646/.well-known/jwks.json"
}

module "consul_setup" {
  source  = "hashicorp-modules/nomad-setup/consul"
  version = "2.0.0"

  # nomad_jwks_url should be reachable by all Consul agents and resolve to
  # multiple Nomad agents for high availability.
  #
  # In a production environment this URL should be handled by an external
  # component, such as a load balancer, a reverse proxy, or a DNS entry with
  # multiple IPs.
  nomad_jwks_url = "http://localhost:4646/.well-known/jwks.json"
}

# Create Vault secret the job needs.
resource "vault_kv_secret_v2" "mongo" {
  mount = "secret"
  name  = "default/workload-identity-demo/mongo"

  data_json = jsonencode({
    root_password = "super-secret"
  })
}

# Register Nomad job.
resource "nomad_job" "workload_identity_demo" {
  depends_on = [
    module.consul_setup,
    module.vault_setup,
    vault_kv_secret_v2.mongo,
  ]

  jobspec = file("${path.module}/files/workload_identity_demo.nomad.hcl")
  detach  = false
}
