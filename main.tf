locals {
  app_settings = {
    "WEBSITES_CONTAINER_START_TIME_LIMIT" = var.start_time_limit
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = var.enable_storage
    "WEBSITES_PORT"                       = var.port
    "DOCKER_REGISTRY_SERVER_USERNAME"     = var.docker_registry_username
    "DOCKER_REGISTRY_SERVER_URL"          = var.docker_registry_url
    "DOCKER_REGISTRY_SERVER_PASSWORD"     = var.docker_registry_password
  }
  app_service_plan_id = coalesce(var.app_service_plan_id, azurerm_app_service_plan.main[0].id)

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
      name  = replace(name, "/_|\\//", "-")
      value = value
    }
  ]

  secure_app_settings = {
    for secret in azurerm_key_vault_secret.main :
    replace(secret.name, "-", "_") => format("@Microsoft.KeyVault(SecretUri=%s)", secret.id)
  }
}

data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

resource "azurerm_app_service_plan" "main" {
  count               = var.app_service_plan_id == "" ? 1 : 0
  name                = "${var.name}-plan"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  kind                = "linux"
  reserved            = true

  sku {
    tier = split("_", var.sku)[0]
    size = split("_", var.sku)[1]
  }

  tags = var.tags
}

resource "azurerm_app_service" "main" {
  name                = var.name
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  app_service_plan_id = local.app_service_plan_id

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
