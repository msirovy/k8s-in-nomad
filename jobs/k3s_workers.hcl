
job "k8s-workers" {
  datacenters = ["dc1"]
  type        = "service"

  group "worker-group" {
    count = 1

    # Ensure workers are spread across your infrastructure
    constraint {
      distinct_hosts = true
    }

    network {
      port "kubelet" { }
    }

    task "k0s-worker" {
      driver = "docker"

      resources {
        cpu    = 2000
        memory = 1024
      }

      # Discovering the CP address dynamically
      template {
        data = <<EOH
{{ range nomadService "k0s-api" }}
K0S_SERVER_IP="{{ .Address }}"
{{ end }}
K0S_TOKEN=""
EOH
        destination = "local/env.txt"
        env         = true
      }

      config {
        image = "k0sproject/k0s:v1.34.3-k0s.0"
        
        # Unique hostname for each worker allocation
        hostname = "k0s-worker-${NOMAD_ALLOC_ID}"

        args = [
          "k0s", "worker",
          # Pass the token directly as an argument
          "${K0S_TOKEN}"
        ]

        privileged   = true
        network_mode = "host"

        # Official k0s-in-docker required mounts
        mount {
          type   = "tmpfs"
          target = "/run"
          tmpfs_options { size = 134217728 } 
        }

        mount {
          type = "bind"
          target = "/dev/kmsg"
          source = "/dev/kmsg"
          readonly = false
        }

        mount {
          type = "bind"
          target = "/lib/modules"
          source = "/lib/modules"
          readonly = true
        }
      }

      service {
        name     = "k8s-worker"
        port     = "kubelet"
        provider = "nomad"
        check {
          type     = "tcp"
          interval = "20s"
          timeout  = "5s"
        }
      }

      # Give k0s time to drain/leave before Nomad kills it
      kill_timeout = "60s"
    }
  }
}

