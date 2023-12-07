# Nomad Workload Identity Terraform Demo

This repository contains a quick demo to setup an environment that uses
[Nomad](https://www.nomadproject.io/) workload identities to retrieve ACL
tokens from [Consul](https://www.consul.io/) and
[Vault](https://www.vaultproject.io/).

It uses [Terraform](https://www.terraform.io/) to configure Consul and Vault so
they are able to exchange JSON Web Tokens (JWT) workload identities from Nomad
for ACL tokens.

To validate the process is working correctly, a sample Nomad job is registered
to run a MongoDB database configured with a password stored in Vault and to
register a service in Consul.

The ACL configuration is done using the following modules:

  * https://registry.terraform.io/modules/hashicorp-modules/nomad-setup/consul
  * https://registry.terraform.io/modules/hashicorp-modules/nomad-setup/vault

## Requirements

The following tools must be installed and available as commands in your
system's `$PATH`:

  * [Consul](https://releases.hashicorp.com/consul/) v1.13.0+
  * [Nomad](https://releases.hashicorp.com/nomad/) v1.7.0+
  * [Terraform](https://releases.hashicorp.com/terraform/) v1.0.0+
  * [Vault](https://releases.hashicorp.com/vault/) v1.11.0+

[Docker](https://www.docker.com/) must also be installed and running to run the
sample job.

## Quick Start

1. Start dev agents for Consul, Nomad, and Vault in three different terminal
   windows.

   > [!WARNING]
   > These commands start development agents with static and unsafe ACL tokens
   > to simplify steps. **This approach should not be used in production**.

   ```console
   consul agent -dev -config-file ./files/consul.hcl
   ```

   ```console
   vault server -dev -dev-root-token-id=root
   ```

   ```console
   sudo CONSUL_HTTP_TOKEN=root nomad agent -dev -config ./files/nomad.hcl
   ```

   > [!NOTE]
   > Nomad clients must always run as `root` in production environments, but
   > when using Docker Desktop in local macOS and Windows environments you may
   > run into file system permission errors. Try running the `nomad` command
   > without `sudo` if you encounter this problem.

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
3. Verify the connection to the database requires authentication by first
   trying to connect without specifying any credentials.

   ```console
   $ nomad alloc exec $(nomad job allocs -t '{{with (index . 0)}}{{.ID}}{{end}}' workload-identity-demo) mongosh --eval 'db.adminCommand({listDatabases:1})' --quiet
   MongoServerError: Command listDatabases requires authentication
   ```
4. Run the command again, but this time specify an user and the password stored
   in Vault.

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
5. Verify the `mongo` service is registered in the Consul catalog.

   ```console
   $ consul catalog services
   consul
   mongo
   nomad
   nomad-client
   ```

## Consul and Vault Namespaces

The Enterprise versions of Consul and Vault support multiple namespaces.

In Vault, each namespace needs to be configured individually. You can create
different [provider aliases][tf_provider_alias] to apply the configuration to
each namespace.

```hcl
# providers.tf

provider "vault" {
  # ...
}

provider "vault" {
  alias = "prod"
  # ...
  namespace = "prod"
}
```

```hcl
# main.tf

module "vault_setup_default" {
  source = "hashicorp-modules/nomad-setup/vault"
  # ...
}

module "vault_setup_prod" {
  source = "hashicorp-modules/nomad-setup/vault"

  providers = {
    vault = vault.prod
  }
  # ...
}
```

In Consul, the configuration module should be applied to the `default`
namespace and you can use the `auth_method_namespace_rules` variable to specify
mappings from Nomad workload identity claims to other Consul namespaces.

```hcl
module "consul_setup" {
  source = "hashicorp-modules/nomad-setup/consul"

  nomad_jwks_url = "http://localhost:4646/.well-known/jwks.json"

  auth_method_namespace_rules = [
    {
      bind_namespace = "$${value.consul_namespace}"
      selector       = "\"consul_namespace\" in value"
    }
  ]
}
```

[tf_provider_alias]: https://developer.hashicorp.com/terraform/language/providers/configuration#alias-multiple-provider-configurations
