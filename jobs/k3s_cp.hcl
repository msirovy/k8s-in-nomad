job "k8s-cp" {
  datacenters = ["dc1"]
  type        = "service"

  group "controller" {
    count = 1

    network {
      port "api"     { static = 6443 }
      port "konnect" { static = 8132 }
    }

    task "k0s-server" {
      driver = "docker"

      # Task-level block (outside config)
      template {
        data = <<EOH
---
apiVersion: k0s.k0sproject.io/v1beta1
kind: ClusterConfig
metadata:
  name: k0s
  namespace: kube-system
spec:
  api:
    address: {{ env "attr.unique.network.ip-address" }}
    k0sApiPort: 9443
    port: 6443
    sans:
      - "{{ env "attr.unique.network.ip-address" }}"
      - "127.0.0.1"
      - "k0s-cp-{{ env "NOMAD_ALLOC_ID" }}"
  controllerManager: {}
  extensions:
    helm:
      concurrencyLevel: 5
  installConfig:
    users:
      etcdUser: etcd
      kineUser: kube-apiserver
      konnectivityUser: konnectivity-server
      kubeAPIserverUser: kube-apiserver
      kubeSchedulerUser: kube-scheduler
  konnectivity:
    adminPort: 8133
    agentPort: 8132
  network:
    clusterDomain: cluster.local
    dualStack:
      enabled: false
    kubeProxy:
      iptables:
        minSyncPeriod: 0s
        syncPeriod: 0s
      ipvs:
        minSyncPeriod: 0s
        syncPeriod: 0s
        tcpFinTimeout: 0s
        tcpTimeout: 0s
        udpTimeout: 0s
      metricsBindAddress: 0.0.0.0:10249
      mode: iptables
      nftables:
        minSyncPeriod: 0s
        syncPeriod: 0s
    kuberouter:
      autoMTU: true
      hairpin: Enabled
      metricsPort: 8080
    nodeLocalLoadBalancing:
      enabled: false
      envoyProxy:
        apiServerBindPort: 7443
        konnectivityServerBindPort: 7132
      type: EnvoyProxy
    podCIDR: 10.221.0.0/16
    provider: kuberouter
    serviceCIDR: 10.251.0.0/16
  scheduler: {}
EOH
        destination = "local/k0s.yaml"
      }

      config {
        image = "k0sproject/k0s:v1.34.3-k0s.0"
        hostname = "k0s-cp-${NOMAD_ALLOC_ID}"

        args = [
          "k0s", "controller",
          "--config=/local/k0s.yaml",
          "--enable-worker"
        ]

        privileged   = true
        network_mode = "host"

        mount {
          type = "bind"
          target = "/dev/kmsg"
          source = "/dev/kmsg"
          readonly = false
        }
        mount {
          type = "bind"
          target = "/var/lib/k0s"
          source = "/var/lib/k8s"
          readonly = false
        }
        mount {
          type = "tmpfs"
          target = "/run"
          tmpfs_options { size = 134217728 } 
        }
      }

      resources {
        cpu    = 2000
        memory = 2048
      }

      service {
        name     = "k0s-api"
        port     = "api"
        provider = "nomad"
      }
    }
  }
}
