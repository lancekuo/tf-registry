variable "aws_region"               {}
variable "project"                  {}
variable "vpc_default_id"           {}
variable "bastion_public_ip"        {}
variable "bastion_private_ip"       {}
variable "security_group_node_id"   {}
variable "route53_internal_zone_id" {}
variable "rsa_key_bastion"          {type="map"}
variable "s3_bucketname_registry"   {}
variable "create_registry_bucket"   {}
variable "enableRegistryPush"       {}

variable "aws_profile"              {}
