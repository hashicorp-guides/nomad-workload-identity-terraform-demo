# Nomad Workload Identity Terraform Demo

This repository contains a quick demo to setup an environment that uses
[Nomad](https://www.nomadproject.io/) workload identities to retrieve ACL
tokens from [Consul](https://www.consul.io/) and
[Vault](https://www.vaultproject.io/).

It uses [Terraform](https://www.terraform.io/) to configure Consul and Vault
ACL systems and register a sample Nomad job that runs a MongoDB database and
registers a service in Consul and reads credentials from Vault.

The ACL configuration is done using the following modules:

  * https://github.com/hashicorp/terraform-consul-nomad-setup/
  * https://github.com/hashicorp/terraform-vault-nomad-setup/

## Requirements

The following tools must be installed and available as commands in your
`$PATH`:

  * [Consul](https://releases.hashicorp.com/consul/) v1.13.0+
  * [Nomad](https://releases.hashicorp.com/nomad/) v1.7.0+
  * [Terraform](https://releases.hashicorp.com/terraform/) v1.0.0+
  * [Vault](https://releases.hashicorp.com/vault/) v1.11.0+

In order to run the sample job [Docker](https://www.docker.com/) must also be
installed and running.

## Quick Start

1. Start dev agents for Consul, Nomad, and Vault in three different terminals.

   > [!WARNING]
   > These commands start development agents with static and unsafe ACL tokens
   > to simplify steps. **This approach should not be used in production**.

   ```console
   consul agent -dev -config ./files/config.hcl
   ```

   ```console
   vault server -dev -dev-root-token-id=root
   ```

   ```console
   sudo CONSUL_HTTP_TOKEN=root nomad agent -dev -config ./files/nomad.hcl
   ```
2. Initialize, apply, and confirm the Terraform configuration.

   ```console
   $ terraform init
   Initializing the backend...
   Initializing modules...
   ...
   Terraform has been successfully initialized!

   You may now begin working with Terraform. Try running "terraform plan" to see
   any changes that are required for your infrastructure. All Terraform commands
   should now work.

   If you ever set or change modules or backend configuration for Terraform,
   rerun this command to reinitialize your working directory. If you forget, other
   commands will detect it and remind you to do so if necessary.
   ```

   ```console
   $ terraform apply
   Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
     + create

   Terraform will perform the following actions:

     # nomad_job.workload_identity_demo will be created
     + resource "nomad_job" "workload_identity_demo" {
         + allocation_ids          = (known after apply)
         + datacenters             = (known after apply)
         + deployment_id           = (known after apply)
         + deployment_status       = (known after apply)
   ...
   Do you want to perform these actions?
     Terraform will perform the actions described above.
     Only 'yes' will be accepted to approve.

     Enter a value: yes

   vault_kv_secret_v2.mongo: Creating...
   module.vault_setup.vault_jwt_auth_backend.nomad: Creating...
   vault_kv_secret_v2.mongo: Creation complete after 0s [id=secret/data/default/workload-identity-demo/mongo]
   module.consul_setup.consul_acl_policy.tasks[0]: Creating...
   module.consul_setup.consul_acl_auth_method.services: Creating...
   module.consul_setup.consul_acl_auth_method.tasks: Creating...
   module.vault_setup.vault_jwt_auth_backend.nomad: Creation complete after 0s [id=jwt-nomad]
   module.consul_setup.consul_acl_policy.tasks[0]: Creation complete after 0s [id=9a5e3bbe-1165-f893-51c4-b8323b6a8588]
   module.vault_setup.vault_policy.nomad_workload[0]: Creating...
   module.consul_setup.consul_acl_role.tasks["default"]: Creating...
   module.consul_setup.consul_acl_auth_method.services: Creation complete after 0s [id=auth-method-nomad-services]
   module.consul_setup.consul_acl_auth_method.tasks: Creation complete after 0s [id=auth-method-nomad-tasks]
   module.vault_setup.vault_policy.nomad_workload[0]: Creation complete after 0s [id=nomad-workload]
   module.consul_setup.consul_acl_role.tasks["default"]: Creation complete after 0s [id=21b8ec63-1b2c-7fee-77b5-69c03e04aa20]
   module.consul_setup.consul_acl_binding_rule.services: Creating...
   module.consul_setup.consul_acl_binding_rule.tasks: Creating...
   module.vault_setup.vault_jwt_auth_backend_role.nomad_workload: Creating...
   module.vault_setup.vault_jwt_auth_backend_role.nomad_workload: Creation complete after 0s [id=auth/jwt-nomad/role/nomad-workload]
   module.consul_setup.consul_acl_binding_rule.services: Creation complete after 0s [id=08f46a52-f09a-c2be-9d62-ad4139a659a1]
   module.consul_setup.consul_acl_binding_rule.tasks: Creation complete after 0s [id=a58d54af-dd18-7e82-36d5-cc9696e8ab40]
   nomad_job.workload_identity_demo: Creating...
   nomad_job.workload_identity_demo: Still creating... [10s elapsed]
   nomad_job.workload_identity_demo: Creation complete after 18s [id=workload-identity-demo]

   Apply complete! Resources: 11 added, 0 changed, 0 destroyed.
   ```
3. Verify connection to the database requires authentication by first trying to
   connect without passing a user and password.

   ```console
   $ nomad alloc exec $(nomad job allocs -t '{{with (index . 0)}}{{.ID}}{{end}}' workload-identity-demo) mongosh --eval 'db.adminCommand({listDatabases:1})' --quiet
   MongoServerError: Command listDatabases requires authentication
   ```
4. Retry the command but this time passing the credentials stored in Vault.

   ```console
   $ nomad alloc exec $(nomad job allocs -t '{{with (index . 0)}}{{.ID}}{{end}}' workload-identity-demo) mongosh --username root --password super-secret --eval 'db.adminCommand({listDatabases:1})' --quiet
   {
     databases: [
       { name: 'admin', sizeOnDisk: Long("102400"), empty: false },
       { name: 'config', sizeOnDisk: Long("12288"), empty: false },
       { name: 'local', sizeOnDisk: Long("73728"), empty: false }
     ],
     totalSize: Long("188416"),
     totalSizeMb: Long("0"),
     ok: 1
   }
   ```
5. Verify the service is registered in the Consul catalog.
   ```console
   $ consul catalog services
   consul
   mongo
   nomad
   nomad-client
   ```
