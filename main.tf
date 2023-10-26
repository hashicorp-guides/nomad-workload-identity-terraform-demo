# Setup Consul and Vault JWT authentication for Nomad.
module "vault_setup" {
  source = "github.com/hashicorp/terraform-vault-nomad-setup"

  nomad_jwks_url = "http://localhost:4646/.well-known/jwks.json"
}

module "consul_setup" {
  source = "github.com/hashicorp/terraform-consul-nomad-setup"

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
