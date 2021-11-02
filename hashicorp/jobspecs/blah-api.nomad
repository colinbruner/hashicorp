job "blah-api" {
  datacenters = ["dc1"]

  group "ingress-group" {
    network {
      mode = "bridge"

      port "inbound" {
        static = 8083
        to     = 8083
      }
    }

    service {
      name = "blah-ingress-service"
      port = "8083"

      connect {
        gateway {

          proxy {}

          # Consul Ingress Gateway Configuration Entry.
          ingress {
            listener {
              port     = 8083
              protocol = "http"
              service {
                hosts = ["blah-api.id-me.io"]
                name = "blah-api"
              }
            }
          }

        }
      }
    }
  }

  group "generator" {
    network {
      mode = "host"
      port "api" {
        to = "9001"
      }
    }

    service {
      name = "blah-api"
      port = "9001"

      connect {
        native = true
      }
    }

    task "generate" {
      driver = "docker"

      config {
        image        = "hashicorpnomad/uuid-api:v5"
        network_mode = "host"
      }

      env {
        BIND = "0.0.0.0"
        PORT = "9001"
      }
    }
  }
}
