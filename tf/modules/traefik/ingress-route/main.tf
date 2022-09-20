/***
-------------------------------------------------------
A Terraform reusable module for deploying microservices
-------------------------------------------------------
Define input variables to the module.
***/
variable app_name {
  type = string
}
variable namespace {
  type = string
}
variable svc_gateway {
  type = string
}
variable svc_kibana {
  type = string
}
variable middleware_rate_limit {
  type = string
}
variable middleware_compress {
  type = string
}
variable middleware_gateway_basic_auth {
  type = string
}
variable middleware_dashboard_basic_auth {
  type = string
}
variable middleware_kibana_basic_auth {
  type = string
}
variable middleware_security_headers {
  type = string
}
variable tls_store {
  type = string
}
variable tls_options {
  type = string
}
variable secret_name {
  type = string
}
variable issuer_name {
  type = string
}
variable host_name {
  type = string
}
variable service_name {
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
    }
    #
    spec = {
      entryPoints = [  # Listening ports.
        "web",
        "websecure"
      ]
      routes = [
        {
          kind = "Rule"
          match = "Host(`${var.host_name}`, `www.${var.host_name}`) && (Path(`/upload`) || Path(`/api/upload`))"
          priority = 50
          middlewares = [
            {
              name = var.middleware_rate_limit
              namespace = var.namespace
            },
            {
              name = var.middleware_security_headers
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
          match = "Host(`${var.host_name}`, `www.${var.host_name}`) && (Path(`/video`) || Path(`/api/video`))"
          priority = 50
          middlewares = [
            {
              name = var.middleware_rate_limit
              namespace = var.namespace
            },
            {
              name = var.middleware_compress
              namespace = var.namespace
            },
            {
              name = var.middleware_security_headers
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
          match = "Host(`${var.host_name}`, `www.${var.host_name}`) && Path(`/history`)"
          priority = 50
          middlewares = [
            {
              name = var.middleware_rate_limit
              namespace = var.namespace
            },
            {
              name = var.middleware_security_headers
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
          match = "Host(`${var.host_name}`, `www.${var.host_name}`) && (PathPrefix(`/dashboard`) || PathPrefix(`/api`))"
          priority = 40
          middlewares = [
            {
              name = var.middleware_dashboard_basic_auth
              namespace = var.namespace
            },
            {
              name = var.middleware_security_headers
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
        },
        {
          kind = "Rule"
          match = "Host(`${var.host_name}`, `www.${var.host_name}`) && PathPrefix(`/ping`)"
          priority = 40
          middlewares = [
            {
              name = var.middleware_dashboard_basic_auth
              namespace = var.namespace
            },
            {
              name = var.middleware_security_headers
              namespace = var.namespace
            }
          ]
          services = [
            {
              kind = "TraefikService"
              # If you enable the API, a new special service named api@internal is created and can
              # then be referenced in a router.
              name = "ping@internal"
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
        },
        {
          kind = "Rule"
          # match = "Host(`169.46.98.220.nip.io`) && PathPrefix(`/`)"
          # match = "Host(`memories.mooo.com`) && (PathPrefix(`/`) || Path(`/upload`) || Path(`/api/upload`))"
          match = "Host(`${var.host_name}`, `www.${var.host_name}`) && PathPrefix(`/`)"
          # See https://doc.traefik.io/traefik/v2.0/routing/routers/#priority
          priority = 20
          # The rule is evaluated 'before' any middleware has the opportunity to work, and 'before'
          # the request is forwarded to the service.
          # Middlewares are applied in the same order as their declaration in router.
          middlewares = [
            {
              name = var.middleware_gateway_basic_auth
              namespace = var.namespace
            },
            {
              name = var.middleware_rate_limit
              namespace = var.namespace
            },
            {
              name = var.middleware_security_headers
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
          match = "Host(`${var.host_name}`, `www.${var.host_name}`) && PathPrefix(`/kibana`)"
          priority = 40
          middlewares = [
            {
              name = var.middleware_kibana_basic_auth
              namespace = var.namespace
            },
            {
              name = var.middleware_security_headers
              namespace = var.namespace
            }
          ]
          services = [
            {
              kind = "Service"
              name = var.svc_kibana
              namespace = var.namespace
              port = 5601  # K8s service.
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
        },
        
        # Define a low-priority catchall rule that kicks in only if other rules for defined
        # services can't handle the request.
        # {
        #   kind = "Rule"
        #   match = "HostRegexp(`{host:.+}`)"
        #   # Set priority to 1 (lowest) to ensure this rule catches all requests not caught by the
        #   # other rules.
        #   priority = 1
        #   middlewares = [
        #     {
        #       name = var.middleware_error_page
        #       namespace = var.namespace
        #     }
        #   ]
        #   services = [
        #     {
        #       kind = "Service"
        #       name = var.svc_error_page
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
        # }
        ###########################################################################################
        # whoami                                                                                  #
        ###########################################################################################
        # {
        #   kind = "Rule"
        #   match = "Host(`${var.host_name}`, `www.${var.host_name}`) && Path(`/whoami`)"
        #   priority = 30
        #   services = [
        #     {
        #       kind = "Service"
        #       name = "mem-whoami"
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
        # }
      ]
      tls = {
        certResolver = "le"
        domains = [
          {
            main = var.host_name
            sans = [  # URI Subject Alternative Names
              "www.${var.host_name}"
            ]
          }
        ]
        secretName = var.secret_name
        store = {
          name = var.tls_store
        }
        options = {
          name = var.tls_options
          namespace = var.namespace
        }
      }
    }
  }
}
