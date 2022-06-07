/***
-------------------------------------------------------
A Terraform reusable module for deploying microservices
-------------------------------------------------------
Define input variables to the module.
***/
variable "app_name" {
  type = string
}
variable "namespace" {
  type = string
}
variable "svc_gateway" {
  type = string
}
variable "middleware_gateway" {
  type = string
}
variable "middleware_dashboard" {
  type = string
}
variable "middleware_redirect_https" {
  type = string
}
variable "tls_options" {
  type = string
}
variable "secret_name" {
  type = string
}
variable "issuer_name" {
  type = string
}
variable "host_name" {
  type = string
}
variable "service_name" {
  type = string
}

resource "kubernetes_manifest" "ingress-route" {
  manifest = {
    apiVersion = "traefik.containo.us/v1alpha1"
    # This CRD is Traefik-specific.
    kind = "IngressRoute"
    metadata = {
      name = var.service_name
      namespace = var.namespace
      labels = {
        app = var.app_name
      }
      annotations = {
        # https://cert-manager.io/v0.15-docs/usage/ingress/#supported-annotations
        # "cert-manager.io/issuer" = var.issuer_name
        # "acme.cert-manager.io/http01-edit-in-place" = true
        # "kubernetes.io/ingress.class" = "traefik"
        # "traefik.ingress.kubernetes.io/router.tls" = true
        # "traefik.http.routers.traefik.entrypoints" = "websecure"
        # "traefik.http.routers.traefik.tls.certresolver" = "le"
        # certmanager.k8s.io/acme-challenge-type: http01
      #   # traefik.ingress.kubernetes.io/frontend-entry-points: http,https
      }
    }
    #
    spec = {
      # If not specified, HTTP routers will accept requests from all defined entry points. If you
      # want to limit the router scope to a set of entry points, set the entryPoints option.
      # Traefik handles requests using the web (HTTP) and websecure (HTTPS) entrypoints.
      entryPoints = [  # Listening ports.
        "web",
        "websecure"
      ]
      routes = [
        # {
        #   kind = "Rule"
        #   match = "Host(`${var.host_name}`, `www.${var.host_name}`) && (Path(`/upload`) || Path(`/api/upload`))"
        #   priority = 21
        #   middlewares = [
        #     {
        #       name = var.middleware_gateway
        #       namespace = var.namespace
        #     },
        #     {
        #       name = var.middleware_redirect_https
        #       namespace = var.namespace
        #     }
        #   ]
        #   services = [
        #     {
        #       kind = "Service"
        #       name = var.svc_gateway
        #       namespace = var.namespace
        #       port = 80  # K8s service.
        #       weight = 1
        #       passHostHeader = true
        #       responseForwarding = {
        #         flushInterval = "100ms"
        #       }
        #       strategy = "RoundRobin"
        #     }
        #   ]
        # },
        /*******
        {
          kind = "Rule"
          match = "Host(`memories.mooo.com`) && (Path(`/video`) || Path(`/api/video`))"
          priority = 21
          middlewares = [
            {
              name = var.middleware_gateway
              namespace = var.namespace
            }
          ]
          services = [
            {
              kind = "Service"
              name = var.svc_gateway
              namespace = var.namespace
              port = 80  # K8s service.
              weight = 1
              passHostHeader = true
              responseForwarding = {
                flushInterval = "100ms"
              }
              strategy = "RoundRobin"
            }
          ]
        },
        {
          kind = "Rule"
          match = "Host(`memories.mooo.com`) && Path(`/rabbitmq`)"
          priority = 21
          middlewares = [
            {
              name = var.middleware_rabbitmq1
              namespace = var.namespace
            }
          ]
          services = [
            {
              kind = "Service"
              name = var.svc_rabbitmq
              namespace = var.namespace
              port = 15672  # K8s service.
              weight = 1
              passHostHeader = true
              responseForwarding = {
                flushInterval = "100ms"
              }
              strategy = "RoundRobin"
            }
          ]
        },
        *****/
        {
          kind = "Rule"
          # For testing, use one of the free wildcard DNS services for IP addresses (xip.io,
          # nip.io (https://nip.io/), sslip.io (https://sslip.io/), ip6.name, and hipio). By using
          # one of these services, the /etc/hosts file does not need to be changed.
          match = "Host(`${var.host_name}`, `www.${var.host_name}`) && PathPrefix(`/`)"
          # match = "Host(`${var.host_name}`) && PathPrefix(`/`)"
          # match = "Host(`169.46.98.220.nip.io`) && PathPrefix(`/`)"
          # match = "Host(`memories.mooo.com`) && (PathPrefix(`/`) || Path(`/upload`) || Path(`/api/upload`))"
          priority = 21
          # The rule is evaluated 'before' any middleware has the opportunity to work, and 'before'
          # the request is forwarded to the service.
          # Middlewares are applied in the same order as their declaration in router.
          middlewares = [
            # {
            #   name = var.middleware_gateway
            #   namespace = var.namespace
            # },
            {
              name = var.middleware_redirect_https
              namespace = var.namespace
            }
          ]
          services = [
            {
              kind = "Service"
              name = var.svc_gateway
              namespace = var.namespace
              port = 80  # K8s service.
              weight = 1
              passHostHeader = true
              responseForwarding = {
                flushInterval = "100ms"
              }
              strategy = "RoundRobin"
            }
          ]
        },
        {
          kind = "Rule"
          # match = "Host(`${var.host_name}`, `www.${var.host_name}`) && (PathPrefix(`/dashboard`) || PathPrefix(`/api`))"
          match = "Host(`${var.host_name}`) && (PathPrefix(`/dashboard`) || PathPrefix(`/api`))"
          # match = "Host(`169.46.98.220.nip.io`) && (PathPrefix(`/dashboard`) || PathPrefix(`/api`))"
          priority = 20
          middlewares = [
            # {
            #   name = var.middleware_dashboard
            #   namespace = var.namespace
            # },
            {
              name = var.middleware_redirect_https
              namespace = var.namespace
            }
          ]
          services = [
            {
              kind = "TraefikService"
              # If you enable the API, a new special service named api@internal is created and can
              # then be referenced in a router.
              name = "api@internal"
              port = 9000  # K8s service.
              # (default 1) A weight used by the weighted round-robin strategy (WRR).
              weight = 1
              # (default true) PassHostHeader controls whether to leave the request's Host Header
              # as it was before it reached the proxy, or whether to let the proxy set it to the
              # destination (backend) host.
              passHostHeader = true
              responseForwarding = {
                # (default 100ms) Interval between flushes of the buffered response body to the
                # client.
                flushInterval = "100ms"
              }
              strategy = "RoundRobin"
            }
          ]
        }
      ]
      # When a TLS section is specified, it instructs Traefik that the current router is dedicated
      # to HTTPS requests only (and that the router should ignore HTTP (non TLS) requests). Traefik
      # will terminate the SSL connections (meaning that it will send decrypted data to the
      # services).
      #
      # To perform an analysis of the TLS handshake using SSLLabs, go to
      # https://www.ssllabs.com/ssltest/.
      tls = {
        # Placing a host in the TLS config will indicate a certificate should be created.
        domains = [
          {
            main = var.host_name
            sans = [  # URI Subject Alternative Names
              "www.${var.host_name}"
            ]
          }
        ]
        # certResolver = "le"
        # Use the secret created by cert-manager to terminate the TLS connection.
        # cert-manager will store the created certificate in this secret.
        secretName = var.secret_name
        # store = {
        #   name = var.tls_store
        # }
        # options = {
        #   name = var.tls_options
        #   namespace = var.namespace
        # }
      }
    }
  }
}
