variable "one_endpoint" {}
variable "one_username" {}
variable "one_password" {}
variable "one_flow_endpoint" {}

provider "opennebula" {
  endpoint      = "${var.one_endpoint}"
  flow_endpoint = "${var.one_flow_endpoint}"
  username      = "${var.one_username}"
  password      = "${var.one_password}"
}

terraform {
  required_providers {
    opennebula  = {
      source    = "OpenNebula/opennebula"
      version   = "0.5.1"
    }
  }
}

data "opennebula_group" "users" {
    count   = 2
    name    = "users-${count.index+1}"
}

resource "opennebula_virtual_network" "private-network" {
    count             = 2
    name              = "network-${count.index+1}"
    bridge            = "br0"
    physical_device   = "eth0"
    group             = data.opennebula_group.users[count.index].name
    network_mask      = "255.255.255.0"
    gateway           = "172.16.0.1"
    permissions       = "640"
    type              = "vxlan"
    automatic_vlan_id = true
    ar {
        ar_type = "IP4"
        size    = 254
        ip4     = "172.16.0.1"
    } 
}

data "opennebula_template" "router" {
    name = "Service VNF" 
}

data "opennebula_virtual_network" "public" {
    name = "public"  
}

data "opennebula_virtual_network" "private" {
    count   = 2
    name    = "network-${count.index+1}"  
}

resource "opennebula_virtual_machine" "router_nat" {
    count       = 2
    name        = "router-${count.index+1}"
    template_id = data.opennebula_template.router.id
    permissions = "640"
    group       = data.opennebula_group.users[count.index].name 

    context = {
        ONEAPP_VNF_NAT4_ENABLED = "YES"
        ONEAPP_VNF_NAT4_INTERFACES_OUT = "eth0"
        ONEAPP_VNF_ROUTER4_ENABLED = "YES"
    }
    
    nic {
      model      = "virtio"
      network_id = data.opennebula_virtual_network.public.id
    }

    nic {
      model      = "virtio"
      network_id = data.opennebula_virtual_network.private[count.index].id
      ip         = "172.16.0.1"
    }
}

data "opennebula_template" "centos" {
    name = "CentOS 8 Stream" 
}

resource "opennebula_virtual_machine" "srv" {
    count       = 2
    name        = "srv-${count.index+1}"
    template_id = data.opennebula_template.centos.id
    permissions = "640"
    group       = data.opennebula_group.users[count.index].name 

    context = {
        SET_HOSTNAME  = "$NAME"
        PASSWORD      = "toor"
    }

    nic {
      model      = "virtio"
      network_id = data.opennebula_virtual_network.private[count.index].id
      ip         = "172.16.0.2"
    }
}
