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

  resource_group_name = "${azurerm_resource_group.example.name}"

  container_type = "docker"

  container_image = "innovationnorway/python-hello-world:latest"
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

  resource_group_name = "${azurerm_resource_group.example.name}"

  container_type = "compose"

  container_config = <<EOF
version: '3'
services:
  web:
    image: "innovationnorway/python-hello-world"
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

  resource_group_name = "${azurerm_resource_group.example.name}"

  container_type = "kube"

  container_config = <<EOF
apiVersion: v1
kind: Pod
metadata:
    name: hello-world
spec:
  containers:
  - name: web
    image: innovationnorway/python-hello-world
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

  resource_group_name = "${azurerm_resource_group.example.name}"

  container_type = "kube"

  container_config = "${file("kubernetes-pod.yaml")}"
}
```

### Configuration from URL (remote)

```hcl
resource "azurerm_resource_group" "example" {
  name     = "example-resources"
  location = "westeurope"
}

data "http" "container_config" {
  url = "https://raw.githubusercontent.com/innovationnorway/python-hello-world/master/docker-compose.yml"
}

module "web_app_container" {
  source = "innovationnorway/web-app-container/azurerm"

  name = "hello-world"

  resource_group_name = "${azurerm_resource_group.example.name}"

  container_type = "compose"

  container_config = "${data.http.container_config.body}"
}
```

## Arguments

| Name | Type | Description |
| --- | --- | --- |
| `name` | `string` | The name of the web app. |
| `resource_group_name` | `string` | The name of an existing resource group to use for the web app. |
| `container_type` | `string` | Type of container. The options are: `docker`, `compose` and `kube`. Default: `docker`. |
| `container_config` | `string` | Configuration for the container. This should be YAML. |
| `container_image` | `string` | Container image name. Example: `innovationnorway/python-hello-world:latest`. |
| `port` | `string` | The value of the expected container port number. |
| `enable_storage` | `bool` | Mount an SMB share to the `/home/` directory. Default: `false`. |
| `start_time_limit` | `string` | Configure the amount of time (in seconds) the app service will wait before it restarts the container. Default: `230`. | 
| `command` | `string` | A command to be run on the container. |
| `app_service_plan_id` | `string` | The ID of an existing app service plan to use for the web app. |
| `sku_tier` | `string` | The pricing tier of an app service plan to use for the web app. Default: `Standard`. |
| `sku_size` | `string` | The instance size of an app service plan to use for the web app. Default: `S1`. |
| `https_only` | `bool` | Redirect all traffic made to the web app using HTTP to HTTPS. Default: `true`. |
| `ftps_state` | `string` | Set the FTPS state value the web app. The options are: `AllAllowed`, `Disabled` and `FtpsOnly`. Default: `Disabled`. |
| `custom_hostnames` | `list` | List of custom hostnames to use for the web app. |
| `docker_registry_username` | `string` | The container registry username. |
| `docker_registry_url` | `string` | The container registry url. Default: `https://index.docker.io` |
| `docker_registry_password` | `string` | The container registry password. |
