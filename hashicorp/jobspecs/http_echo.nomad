job "http_echo" {
  datacenters = ["dc1"]

  group "http" {
    network {
      port "http" {
        to = "8080"
      }
    }
    task "server" {
      driver = "docker"

      service {
        name = "http-echo"
        port = "http"
      }

      config {
        image = "hashicorp/http-echo"
        ports = ["http"]
        args = [
          "-listen",
          ":8080",
          "-text",
          "Hello World!!!!",
        ]
      }
    }
  }
}
