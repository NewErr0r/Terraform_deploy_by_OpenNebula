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

data "template_file" "group_template" {
  template = file("group_template.txt")
}

resource "opennebula_group" "users" {
  count    = 2
  name     = "users-${count.index+1}"  
  template = data.template_file.group_template.rendered
}

data "opennebula_group" "gr" {
  count = 2
  name  = "users-${count.index+1}"   
}

resource "opennebula_user" "user" {
  count         = 2
  name          = "user-${count.index+1}" 
  password      = "P@ssw0rd"
  auth_driver   = "core"
  primary_group = data.opennebula_group.gr[count.index].id
}