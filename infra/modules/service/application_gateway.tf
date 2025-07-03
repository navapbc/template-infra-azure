data "azurerm_location" "location" {
  location = var.resource_group_location
}

locals {
  logical_zones = coalesce([for zone in data.azurerm_location.location.zone_mappings : zone.logical_zone], [])

  # azurerm_virtual_network.example.name}-beap"
  gateway_resource_prefix = var.resource_group_name

  backend_address_pool_name                 = "${local.gateway_resource_prefix}-beap"
  frontend_port_http_name                   = "${local.gateway_resource_prefix}-feport-http"
  frontend_port_https_name                  = "${local.gateway_resource_prefix}-feport-https"
  frontend_ip_configuration_name            = "${local.gateway_resource_prefix}-feip"
  http_setting_name                         = "${local.gateway_resource_prefix}-be-htst"
  http_listener_name                        = "${local.gateway_resource_prefix}-lstn-http"
  https_listener_name                       = "${local.gateway_resource_prefix}-lstn-https"
  http_request_routing_rule_name            = "${local.gateway_resource_prefix}-rqrt-http"
  https_request_routing_rule_name           = "${local.gateway_resource_prefix}-rqrt-https"
  http_to_https_redirect_configuration_name = "${local.gateway_resource_prefix}-rdrcfg"
  ssl_cert_name                             = "${local.gateway_resource_prefix}-ssl-cert"
  backend_probe_name                        = "${local.gateway_resource_prefix}-be-probe"

  # TODO if using IP Address to the environment? Would not be needed if the backend_address_pool.fqdns is set
  backend_host_name = azurerm_container_app.service.ingress[0].fqdn
}

resource "azurerm_public_ip" "pip_v4" {
  count = var.application_gateway_subnet_id != null ? 1 : 0

  name                = var.service_name
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = local.logical_zones

  ip_version = "IPv4"

  lifecycle {
    prevent_destroy = false
  }
}

resource "azurerm_user_assigned_identity" "app_gateway" {
  count = var.application_gateway_subnet_id != null ? 1 : 0

  name                = "${var.service_name}-gateway-uai"
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
}

resource "azurerm_role_assignment" "app_gateway_cert_secret" {
  count = var.application_gateway_subnet_id != null && var.domain_certificate_secret_id != null ? 1 : 0

  # TODO: this should be scoped to the particular cert, but this isn't working
  # https://github.com/hashicorp/terraform-provider-azurerm/issues/24047
  # scope                = var.domain_certificate_secret_id
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.app_gateway[0].principal_id

  # TODO: need this?
  # skip_service_principal_aad_check = var.is_temporary
  skip_service_principal_aad_check = true
}

resource "azurerm_application_gateway" "service" {
  count = var.application_gateway_subnet_id != null ? 1 : 0

  # TODO: add depends on the role assignment above? So it can access the cert?
  # But only when we've defined a cert...

  name                = var.service_name
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  zones               = local.logical_zones

  # TODO: probably make configurable, or just leave out
  enable_http2 = true

  sku {
    name     = var.application_gateway_sku_name
    tier     = var.application_gateway_sku_name
    capacity = var.application_gateway_sku_name == "Basic" ? 1 : null
  }

  # Note the scaling doesn't apply to the `Basic` SKU, which has it's own
  # internal limits/automatically scales to handle 200 reqs/sec
  #
  # https://learn.microsoft.com/en-us/azure/application-gateway/application-gateway-autoscaling-zone-redundant
  dynamic "autoscale_configuration" {
    for_each = var.application_gateway_sku_name != "Basic" ? [true] : []

    content {
      # `desired_instance_count` refers the number of service instances, but use
      # as a signal for the gateway scaling as well
      #
      # min_capacity choices:
      #
      # 0 -> still pay the fixed costs for the gateway, but compute
      # units scale to zero with no traffic, saving some money
      #
      # 2 -> so there's at least *some* zone redundancy
      min_capacity = var.desired_instance_count == 0 ? 0 : 2
    }
  }

  # checkov:skip=CKV_AZURE_120:TODO: WAF support

  gateway_ip_configuration {
    name      = "${local.gateway_resource_prefix}-gateway-ip-configuration"
    subnet_id = var.application_gateway_subnet_id
  }

  frontend_port {
    name = local.frontend_port_http_name
    port = 80
  }

  frontend_port {
    name = local.frontend_port_https_name
    port = 443
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.pip_v4[0].id
  }

  backend_address_pool {
    name = local.backend_address_pool_name
    # TODO if we need to use the FQDN, then we'll need to setup Private DNS and
    # a Private Link
    # fqdns = [azurerm_container_app.service.ingress[0].fqdn]
    ip_addresses = [data.azurerm_container_app_environment.env.static_ip_address]
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    port                  = 443
    protocol              = "Https"
    # request_timeout       = 60
    # TODO if using IP Address to the environment? Would not be needed if the backend_address_pool.fqdns is set
    host_name  = local.backend_host_name
    probe_name = local.backend_probe_name
  }

  probe {
    name                = local.backend_probe_name
    host                = local.backend_host_name
    interval            = 60 # seconds
    protocol            = "Https"
    path                = "/health"
    timeout             = 30 # seconds
    unhealthy_threshold = 5

    match {
      status_code = ["200-299"]
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.app_gateway[0].id]
  }

  ssl_certificate {
    name                = local.ssl_cert_name
    key_vault_secret_id = var.domain_certificate_secret_id
  }

  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20220101S"
  }

  # checkov:skip=CKV_AZURE_217:Allow Http to direct to Https
  http_listener {
    name                           = local.http_listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_http_name
    protocol                       = "Http"
  }

  http_listener {
    name                           = local.https_listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_https_name
    protocol                       = "Https"
    ssl_certificate_name           = local.ssl_cert_name
  }

  redirect_configuration {
    name                 = local.http_to_https_redirect_configuration_name
    redirect_type        = "Permanent"
    target_listener_name = local.https_listener_name
    include_path         = true
    include_query_string = true
  }

  request_routing_rule {
    name               = local.http_request_routing_rule_name
    priority           = 2
    rule_type          = "Basic"
    http_listener_name = local.http_listener_name

    redirect_configuration_name = local.http_to_https_redirect_configuration_name
  }

  request_routing_rule {
    name                       = local.https_request_routing_rule_name
    priority                   = 1
    rule_type                  = "Basic"
    http_listener_name         = local.https_listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }
}

resource "azurerm_dns_a_record" "service" {
  provider = azurerm.domain

  count = var.manage_dns && local.custom_fqdn != null && local.use_application_gateway ? 1 : 0

  name                = local.dns_sub == null || local.dns_sub == "" ? "@" : local.dns_sub
  resource_group_name = var.domain_resource_group_name
  zone_name           = var.domain_hosted_zone_name
  ttl                 = 300
  target_resource_id  = azurerm_public_ip.pip_v4[0].id
}
