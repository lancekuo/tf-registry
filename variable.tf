variable "project" {}
variable "region" {}
variable "vpc_default_id" {}
variable "bastion_public_ip" {}
variable "bastion_private_ip" {}
variable "bastion_private_key_path" {}

provider "aws" {
    alias  = "${var.region}"
    region = "${var.region}"
}
