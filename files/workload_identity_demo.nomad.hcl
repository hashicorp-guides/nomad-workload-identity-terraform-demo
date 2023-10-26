job "workload-identity-demo" {
  vault {}

  group "db" {
    network {
      port "db" {
        to = 27017
      }
    }

    service {
      name = "mongo"
      port = "db"
    }

    task "mongo" {
      driver = "docker"

      config {
        image          = "mongo:7"
        ports          = ["db"]
        auth_soft_fail = true
      }

      template {
        data        = <<EOF
MONGO_INITDB_ROOT_USERNAME=root
MONGO_INITDB_ROOT_PASSWORD={{with secret "secret/data/default/workload-identity-demo/mongo"}}{{.Data.data.root_password}}{{end}}
EOF
        destination = "${NOMAD_SECRETS_DIR}/env"
        env         = true
      }
    }
  }
}
