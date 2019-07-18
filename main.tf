locals {
  app_settings = {
    "WEBSITES_CONTAINER_START_TIME_LIMIT" = var.start_time_limit
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = var.enable_storage
    "WEBSITES_PORT"                       = var.port
    "DOCKER_REGISTRY_SERVER_USERNAME"     = var.docker_registry_username
    "DOCKER_REGISTRY_SERVER_URL"          = var.docker_registry_url
    "DOCKER_REGISTRY_SERVER_PASSWORD"     = var.docker_registry_password
  }

  container_type   = upper(var.container_type)
  container_config = base64encode(var.container_config)

  supported_container_types = {
    COMPOSE = true
    DOCKER  = true
    KUBE    = true
  }
  check_supported_container_types = local.supported_container_types[local.container_type]

  linux_fx_version = "${local.container_type}|${local.container_type == "DOCKER" ? var.container_image : local.container_config}"

  ip_restrictions = [
    for prefix in var.ip_restrictions : {
      ip_address  = split("/", prefix)[0]
      subnet_mask = cidrnetmask(prefix)
    }
  ]

  key_vault_secrets = [
    for name, value in var.secure_app_settings : {
      name  = replace(name, "/[^a-zA-Z0-9-]/", "-")
      value = value
    }
  ]

  secure_app_settings = {
    for secret in azurerm_key_vault_secret.main :
    replace(secret.name, "-", "_") => format("@Microsoft.KeyVault(SecretUri=%s)", secret.id)
  }

  default_plan_name = format("%s-plan", var.name)

  plan = merge({
    id   = ""
    name = ""
    sku  = "B1"
  }, var.plan)

  plan_id = coalesce(local.plan.id, azurerm_app_service_plan.main[0].id)

  sku_tier_sizes = {
    "Basic"     = ["B1", "B2", "B3"]
    "Standard"  = ["S1", "S2", "S3"]
    "Premium"   = ["P1", "P2", "P3"]
    "PremiumV2" = ["P1v2", "P2v2", "P3v2"]
  }

  flattened_skus = flatten([
    for tier, sizes in local.sku_tier_sizes : [
      for size in sizes : {
        tier = tier
        size = size
      }
    ]
  ])

  sku_tiers = { for sku in local.flattened_skus : sku.size => sku.tier }
}

data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

resource "azurerm_app_service_plan" "main" {
  count               = local.plan.id == "" ? 1 : 0
  name                = coalesce(local.plan.name, local.default_plan_name)
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  kind                = "linux"
  reserved            = true

  sku {
    tier = local.sku_tiers[local.plan.sku]
    size = local.plan.sku
  }

  tags = var.tags
}

resource "azurerm_app_service" "main" {
  name                = var.name
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  app_service_plan_id = local.plan_id

  client_affinity_enabled = false

  https_only = var.https_only

  site_config {
    always_on        = var.always_on
    app_command_line = var.command
    ftps_state       = var.ftps_state
    ip_restriction   = local.ip_restrictions
    linux_fx_version = local.linux_fx_version
  }

  app_settings = merge(var.app_settings, local.secure_app_settings, local.app_settings)

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags

  depends_on = [azurerm_key_vault_secret.main]
}

resource "azurerm_app_service_custom_hostname_binding" "main" {
  count               = length(var.custom_hostnames)
  hostname            = var.custom_hostnames[count.index]
  app_service_name    = azurerm_app_service.main.name
  resource_group_name = data.azurerm_resource_group.main.name
}

resource "azurerm_key_vault_access_policy" "main" {
  count              = length(var.secure_app_settings) > 0 ? 1 : 0
  key_vault_id       = var.key_vault_id
  tenant_id          = azurerm_app_service.main.identity[0].tenant_id
  object_id          = azurerm_app_service.main.identity[0].principal_id
  secret_permissions = ["get"]
}

resource "azurerm_key_vault_secret" "main" {
  count        = length(local.key_vault_secrets)
  key_vault_id = var.key_vault_id
  name         = local.key_vault_secrets[count.index].name
  value        = local.key_vault_secrets[count.index].value
}
