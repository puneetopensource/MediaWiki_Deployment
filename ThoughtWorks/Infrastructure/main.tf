data "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.env}"
  resource_group_name = var.resource_group
}

resource "azurerm_resource_group" "rg_k8s" {
  name = "rg-aks-${var.env}"
  location = var.location
  tags = {
    "environment" = "${var.env}",
  }
}

resource "azurerm_subnet" "snet" {
  name                 = "k8s-subnet"
  resource_group_name  = var.resource_group
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.6.0.0/16"]
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-${var.env}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_k8s.name
  kubernetes_version  = "1.22.6"
  dns_prefix          = "aks-${var.env}"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_D2_v2"
    vnet_subnet_id = azurerm_subnet.snet.id
  }

  network_profile {
    network_plugin = "azure"
    network_mode   = null
    network_policy = "azure"
  }

  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    ignore_changes = [
        api_server_authorized_ip_ranges
    ]
  }

}

resource "azurerm_kubernetes_cluster_node_pool" "k8s_nodepool" {
  name                  = "lnxb4"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = "Standard_B4ms"
  node_count            = 1
  vnet_subnet_id        = azurerm_subnet.snet.id
  os_type               = "Linux"
  enable_auto_scaling   = true
  max_count             = 10
  min_count             = 3
  max_pods              = 15
  
  lifecycle {
    ignore_changes = [
        node_count
    ]
  }
}

