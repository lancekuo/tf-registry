resource "aws_route53_record" "registry" {
    zone_id  = "${var.route53_internal_zone_id}"
    name     = "${terraform.workspace}-registry.${var.project}.internal"
    type     = "A"
    ttl      = "300"
    records  = ["${var.bastion_private_ip}"]
}

resource "aws_iam_access_key" "register_puller" {
    user     = "${aws_iam_user.register_puller.name}"
}

resource "aws_iam_user" "register_puller" {
    name     = "${terraform.workspace}-${var.project}-docker-register-puller"
    path     = "/system/"
}

resource "aws_iam_user_policy" "register_puller_role" {
    name     = "${terraform.workspace}-${var.project}-docker-register-puller"
    user     = "${aws_iam_user.register_puller.name}"

    policy   = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:GetBucketLocation",
                "s3:ListBucketMultipartUploads"
            ],
            "Resource": "${format("arn:aws:s3:::%s", var.s3_bucketname_registry)}"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject"
            ],
            "Resource": "${format("arn:aws:s3:::%s/*", var.s3_bucketname_registry)}"
        }
    ]
}
EOF
}

resource "aws_iam_access_key" "register_pusher" {
    user     = "${aws_iam_user.register_pusher.name}"
}

resource "aws_iam_user" "register_pusher" {
    name     = "${terraform.workspace}-${var.project}-docker-register-pusher"
    path     = "/system/"
}

resource "aws_iam_user_policy" "register_pusher_role" {
    name     = "${terraform.workspace}-${var.project}-docker-register-pusher"
    user     = "${aws_iam_user.register_pusher.name}"

    policy   = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:GetBucketLocation",
                "s3:ListBucketMultipartUploads"
            ],
            "Resource": [
                "${format("arn:aws:s3:::%s", var.s3_bucketname_registry)}",
                "arn:aws:s3:::docker-env-config"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:DeleteObject",
                "s3:ListMultipartUploadParts",
                "s3:AbortMultipartUpload"
            ],
            "Resource": [
                "${format("arn:aws:s3:::%s/*", var.s3_bucketname_registry)}"
            ]
        }
    ]
}
EOF
}

resource "aws_s3_bucket" "registry" {
    count     = "${var.create_bucket}"
    bucket    = "${var.s3_bucketname_registry}"
    acl       = "private"
    lifecycle = {
        ignore_changes  = "*"
        prevent_destroy = true
    }

    tags {
        Name        = "Registry"
        Environment = "${terraform.workspace}"
    }
}

resource "aws_s3_bucket_object" "docker" {
    count     = "${var.create_bucket}"
    bucket    = "${aws_s3_bucket.registry.id}"
    acl       = "private"
    key       = "docker/"
    source    = "/dev/null"
    lifecycle = {
        ignore_changes  = "*"
        prevent_destroy = true
    }
}

resource "null_resource" "registry_trigger" {
    triggers {
        registry_id = "${var.s3_bucketname_registry}"
        record_name = "${aws_route53_record.registry.name}"
        bastion_ip  = "${var.bastion_public_ip}"
    }

    provisioner "remote-exec" {
        inline = [
            "docker rm -f registry_${terraform.workspace} >/dev/null;docker run -d -e REGISTRY_STORAGE=s3 -e REGISTRY_STORAGE_S3_ACCESSKEY=${terraform.workspace == var.ci_workspace_name && var.project == var.ci_project_name ? aws_iam_access_key.register_pusher.id : aws_iam_access_key.register_puller.id} -e REGISTRY_STORAGE_S3_SECRETKEY=${terraform.workspace == var.ci_workspace_name && var.project == var.ci_project_name ? aws_iam_access_key.register_pusher.secret : aws_iam_access_key.register_puller.secret} -e REGISTRY_STORAGE_S3_REGION=${var.aws_region} -e REGISTRY_STORAGE_S3_REGIONENDPOINT=http://s3.${var.aws_region}.amazonaws.com -e REGISTRY_STORAGE_S3_BUCKET=${var.s3_bucketname_registry} -e REGISTRY_STORAGE_S3_V4AUTH=true -e REGISTRY_STORAGE_S3_ROOTDIRECTORY=/ -p 80:5000 --name registry_${terraform.workspace} --restart always registry:2",
        ]
        connection {
            type        = "ssh"
            user        = "ubuntu"
            host        = "${var.bastion_public_ip}"
            private_key = "${file("${path.root}${var.rsa_key_bastion["private_key_path"]}")}"
        }
    }
}

