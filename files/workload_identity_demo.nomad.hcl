job "workload-identity-demo" {

  group "db" {
    network {
      port "db" {
        to = 27017
      }
    }

    service {
      provider = "consul"
      name     = "mongo"
      port     = "db"
    }

    task "mongo" {
      driver = "docker"

      config {
        image          = "mongo:7"
        ports          = ["db"]
        auth_soft_fail = true
      }

      vault {}

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
