#RAILS_ENV=production rails s

job "ruby_minimal" { 
  datacenters = ["dc1"]

  group "app" {
    network {
      port "app-http" {
        to = "3000"
      }
    }

    task "server" {
      driver = "raw_exec"

      # Define a unique Service / Port
      service {
        name = "app-ruby"
        port = "app-http"

        ## Define http healthcheck
        #check {
        #  type     = "http"
        #  path     = "/"
        #  port     = "app-http"
        #  interval = "10s"
        #  timeout  = "2s"
        #}
      }
      ###
      # Download Ruby on Rails git Repo
      ###
      artifact {
        source      = "git::https://github.com/colinbruner/rails-minimal-bootstrap"
        destination = "local/project"
        options {
          # Variablize
          ref = "main"
        }
      }

      ###
      # Download runtime launch script
      ###
      artifact {
        source      = "https://gist.github.com/colinbruner/0104fc8c0c03b4c4394dfecba8ebc54a/raw/1a1e642806a81d45c02d8fa6759bf489284e909b/run.sh"
        destination = "local/"
      }

      # Set to production as a PoC. Needs 'producton' or 'staging' to run on 0.0.0.0
      env {
        # Won't expand $HOME or $PATH vars here
        RAILS_ENV = "development"
      }

      config {
        command = "/bin/bash"
        args = ["local/run.sh"]
      }
    }
  }
}
