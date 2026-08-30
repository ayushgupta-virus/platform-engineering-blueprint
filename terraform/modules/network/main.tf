###############################################################################
# Network module: VNet, public/private/database subnets and NSGs.
#
# Azure subnets are not intrinsically "public" or "private" like AWS. We model
# the tiers with NSG rules and by keeping the AKS/DB subnets isolated from
# inbound internet traffic while allowing the ingress tier to receive 80/443.
###############################################################################

resource "azurerm_virtual_network" "this" {
  name                = "vnet-${var.foundation.name_prefix}"
  location            = var.foundation.location
  resource_group_name = var.foundation.resource_group_name
  address_space       = [var.vnet_cidr]
  tags                = var.foundation.tags
}

# ---- Public / ingress tier -------------------------------------------------
resource "azurerm_subnet" "public" {
  name                 = "snet-public"
  resource_group_name  = var.foundation.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.public_subnet_cidr]
}

resource "azurerm_network_security_group" "public" {
  name                = "nsg-public-${var.foundation.name_prefix}"
  location            = var.foundation.location
  resource_group_name = var.foundation.resource_group_name
  tags                = var.foundation.tags

  security_rule {
    name                       = "allow-https-inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-http-inbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "public" {
  subnet_id                 = azurerm_subnet.public.id
  network_security_group_id = azurerm_network_security_group.public.id
}

# ---- Private / AKS tier ----------------------------------------------------
resource "azurerm_subnet" "aks" {
  name                 = "snet-aks"
  resource_group_name  = var.foundation.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.aks_subnet_cidr]
}

resource "azurerm_network_security_group" "aks" {
  name                = "nsg-aks-${var.foundation.name_prefix}"
  location            = var.foundation.location
  resource_group_name = var.foundation.resource_group_name
  tags                = var.foundation.tags

  # Only allow traffic that originates inside the VNet (e.g. from the ingress
  # tier / load balancer). Deny everything else inbound from the internet.
  security_rule {
    name                       = "allow-vnet-inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "allow-azure-lb-inbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "deny-all-inbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "aks" {
  subnet_id                 = azurerm_subnet.aks.id
  network_security_group_id = azurerm_network_security_group.aks.id
}

# ---- Private / database tier (delegated to PostgreSQL Flexible Server) ------
resource "azurerm_subnet" "db" {
  name                 = "snet-db"
  resource_group_name  = var.foundation.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.db_subnet_cidr]

  delegation {
    name = "postgresql-delegation"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action"
      ]
    }
  }
}

resource "azurerm_network_security_group" "db" {
  name                = "nsg-db-${var.foundation.name_prefix}"
  location            = var.foundation.location
  resource_group_name = var.foundation.resource_group_name
  tags                = var.foundation.tags

  # Only the AKS subnet may reach PostgreSQL on 5432.
  security_rule {
    name                       = "allow-postgres-from-aks"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5432"
    source_address_prefix      = var.aks_subnet_cidr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "deny-all-inbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "db" {
  subnet_id                 = azurerm_subnet.db.id
  network_security_group_id = azurerm_network_security_group.db.id
}
