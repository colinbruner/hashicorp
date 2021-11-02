job "uuid-api" {
  datacenters = ["dc1"]

  group "ingress-group" {
    network {
      mode = "bridge"

      port "inbound" {
        static = 8081
        to     = 8081
      }
    }

    service {
      name = "uuid-ingress-service"
      port = "8081"

      connect {
        gateway {

          proxy {}

          # Consul Ingress Gateway Configuration Entry.
          ingress {
            listener {
              port     = 8081
              protocol = "http"
              service {
                hosts = ["uuid-api.id-me.io"]
                name = "uuid-api"
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
      port "api" {}
    }

    service {
      name = "uuid-api"
      port = "${NOMAD_PORT_api}"
      #port = "api"

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
        PORT = "${NOMAD_PORT_api}"
      }
    }
  }
}

#  group "api" {
#    network {
#      mode = "bridge"
#    }
#
#    service {
#      name = "count-api"
#      port = "9001"
#
#      connect {
#        sidecar_service {}
#      }
#    }
#
#    task "web" {
#      driver = "docker"
#
#      config {
#        image = "hashicorpnomad/counter-api:v3"
#      }
#    }
#  }
#
#  group "dashboard" {
#    network {
#      mode = "bridge"
#
#      port "http" {}
#    }
#
#    service {
#      name = "count-dashboard"
#      port = "http"
#
#      connect {
#        native = true
#      }
#    }
#
#    task "dashboard" {
#      driver = "docker"
#
#      #env {
#      #  COUNTING_SERVICE_URL = "http://${NOMAD_UPSTREAM_ADDR_count_api}"
#      #}
#
#      config {
#        image = "hashicorpnomad/counter-dashboard:v3"
#      }
#    }
#  }
#}
