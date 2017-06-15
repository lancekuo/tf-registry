resource "aws_security_group" "registry" {
    provider    = "aws.${var.region}"
    name        = "${terraform.env}-${var.project}-registry"
    description = "Port for access regisry from nodes"
    vpc_id      = "${var.vpc_default_id}"

    ingress {
        from_port       = 80
        to_port         = 80
        protocol        = "tcp"
        security_groups = ["${var.security_group_node_id}"]
    }
    tags {
        Name    = "${terraform.env}-${var.project}-registry"
        Env     = "${terraform.env}"
        Project = "${var.project}"
    }
}
