variable "aws_region"               {}
variable "project"                  {}
variable "vpc_default_id"           {}
variable "bastion_public_ip"        {}
variable "bastion_private_ip"       {}
variable "security_group_node_id"   {}
variable "route53_internal_zone_id" {}
variable "rsa_key_bastion"          {type="map"}

provider "aws" {
    alias  = "${var.aws_region}"
    region = "${var.aws_region}"
}
