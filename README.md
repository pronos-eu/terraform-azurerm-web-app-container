# Web App for Containers (Azure App Service)

Create Web App for Containers (Azure App Service).

## Example Usage

### Docker (single container)

```hcl
resource "azurerm_resource_group" "example" {
  name     = "example-resources"
  location = "westeurope"
}

module "web_app_container" {
  source = "innovationnorway/web-app-container/azurerm"

  name = "hello-world"

  resource_group_name = azurerm_resource_group.example.name

  container_type = "docker"

  container_image = "innovationnorway/go-hello-world:latest"
}
```

### Docker Compose (multi-container)

```hcl
resource "azurerm_resource_group" "example" {
  name     = "example-resources"
  location = "westeurope"
}

module "web_app_container" {
  source = "innovationnorway/web-app-container/azurerm"

  name = "hello-world"

  resource_group_name = azurerm_resource_group.example.name

  container_type = "compose"

  container_config = <<EOF
version: '3'
services:
  web:
    image: "innovationnorway/go-hello-world"
    ports:
     - "80:80"
  redis:
    image: "redis:alpine"
EOF
}
```

### Kubernetes (multi-container)

```hcl
resource "azurerm_resource_group" "example" {
  name     = "example-resources"
  location = "westeurope"
}

module "web_app_container" {
  source = "innovationnorway/web-app-container/azurerm"

  name = "hello-world"

  resource_group_name = azurerm_resource_group.example.name

  container_type = "kube"

  container_config = <<EOF
apiVersion: v1
kind: Pod
metadata:
    name: hello-world
spec:
  containers:
  - name: web
    image: innovationnorway/go-hello-world
    ports:
      - containerPort: 80
  - name: redis
    image: redis:alpine
EOF
}
```

### Configuration from file (local)

```hcl
resource "azurerm_resource_group" "example" {
  name     = "example-resources"
  location = "westeurope"
}

module "web_app_container" {
  source = "innovationnorway/web-app-container/azurerm"

  name = "hello-world"

  resource_group_name = azurerm_resource_group.example.name

  container_type = "kube"

  container_config = file("kubernetes-pod.yaml")
}
```

### Configuration from URL (remote)

```hcl
resource "azurerm_resource_group" "example" {
  name     = "example-resources"
  location = "westeurope"
}

data "http" "container_config" {
  url = "https://raw.githubusercontent.com/innovationnorway/go-hello-world/master/docker-compose.yml"
}

module "web_app_container" {
  source = "innovationnorway/web-app-container/azurerm"

  name = "hello-world"

  resource_group_name = azurerm_resource_group.example.name

  container_type = "compose"

  container_config = data.http.container_config.body
}
```

### Set environment variables (App Settings)

```hcl
resource "azurerm_resource_group" "example" {
  name     = "example-resources"
  location = "westeurope"
}

module "web_app_container" {
  source = "innovationnorway/web-app-container/azurerm"

  name = "hello-world"

  resource_group_name = azurerm_resource_group.example.name

  container_image = "innovationnorway/go-hello-world:latest"

  app_settings = {
    MESSAGE = "Hello World!"
  }
}
```

### Set sensitive environment variables (App Settings from Key Vault)

```hcl
resource "azurerm_resource_group" "example" {
  name     = "example-resources"
  location = "westeurope"
}

module "web_app_container" {
  source = "innovationnorway/web-app-container/azurerm"

  name = "hello-world"

  resource_group_name = azurerm_resource_group.example.name

  container_image = "innovationnorway/go-hello-world:latest"

  key_vault_id = azurerm_key_vault.example.id

  secure_app_settings = {
    MESSAGE = "Hello World!"
  }
}
```

### Configure IP restrictions

```hcl
resource "azurerm_resource_group" "example" {
  name     = "example-resources"
  location = "westeurope"
}

module "web_app_container" {
  source = "innovationnorway/web-app-container/azurerm"

  name = "hello-world"

  resource_group_name = azurerm_resource_group.example.name

  container_image = "innovationnorway/go-hello-world:latest"

  ip_restrictions = ["192.168.3.4/32", "192.168.2.0/24"]
}
```

## Arguments

| Name | Type | Description |
| --- | --- | --- |
| `name` | `string` | The name of the web app. |
| `resource_group_name` | `string` | The name of an existing resource group to use for the web app. |
| `plan` | `object` | App Service plan properties. This should be `plan` object. |
| `container_type` | `string` | Type of container. The options are: `docker`, `compose` and `kube`. Default: `docker`. |
| `container_config` | `string` | Configuration for the container. This should be YAML. |
| `container_image` | `string` | Container image name. Example: `innovationnorway/go-hello-world:latest`. |
| `port` | `string` | The value of the expected container port number. |
| `enable_storage` | `bool` | Mount an SMB share to the `/home/` directory. Default: `false`. |
| `start_time_limit` | `string` | Configure the amount of time (in seconds) the app service will wait before it restarts the container. Default: `230`. | 
| `command` | `string` | A command to be run on the container. |
| `app_settings` | `map` | Set app settings. These are avilable as environment variables at runtime. |
| `secure_app_settings` | `map` | Set sensitive app settings. Uses Key Vault references as values for app settings. |
| `key_vault_id` | `string` | The ID of an existing Key Vault. Required if `secure_app_settings` is set. |
| `https_only` | `bool` | Redirect all traffic made to the web app using HTTP to HTTPS. Default: `true`. |
| `ftps_state` | `string` | Set the FTPS state value the web app. The options are: `AllAllowed`, `Disabled` and `FtpsOnly`. Default: `Disabled`. |
| `ip_restrictions` | `list` | A list of IP addresses in CIDR format specifying Access Restrictions. |
| `custom_hostnames` | `list` | List of custom hostnames to use for the web app. |
| `docker_registry_username` | `string` | The container registry username. |
| `docker_registry_url` | `string` | The container registry url. Default: `https://index.docker.io` |
| `docker_registry_password` | `string` | The container registry password. |
| `tags` | `map` | A mapping of tags to assign to the web app. |

The `plan` object accepts the following keys:

| Name | Type | Description |
| --- | --- | --- |
| `id` | `string` | The ID of an existing app service plan. |
| `name` | `string` | The name of a new app service plan. |
| `sku_size` | `string` | The SKU size of a new app service plan. The options are: `F1`, `D1`, `B1`, `B2`, `B3`, `S1`, `S2`, `S3`, `P1v2`, `P2v2`, `P3v2`. Default: `F1`. |

List of SKU sizes: 

| Size | Tier | Description |
| --- | --- | --- |
| `F1`, `Free` | Free | Free |
| `D1`, `Shared` | Shared | Shared |
| `B1`, `B2`, `B3` | Basic | Small, Medium, Large |
| `S1`, `S2`, `S3` | Standard | Small, Medium, Large |
| `P1v2`, `P2v2`, `P3v2` | PremiumV2 | Small, Medium, Large |

Read more about [App Service plans](https://docs.microsoft.com/en-us/azure/app-service/overview-hosting-plans).
