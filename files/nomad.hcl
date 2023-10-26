vault {
  enabled = true

  address               = "http://localhost:8200"
  jwt_auth_backend_path = "jwt-nomad"

  default_identity {
    aud = ["vault.io"]
    ttl = "1h"
  }
}

consul {
  enabled = true

  address             = "http://localhost:8500"
  service_auth_method = "nomad-services"
  task_auth_method    = "nomad-tasks"

  service_identity {
    aud = ["consul.io"]
    ttl = "1h"
  }

  task_identity {
    aud = ["consul.io"]
    ttl = "1h"
  }
}
