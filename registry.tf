resource "aws_route53_zone" "internal" {
    provider = "aws.${var.region}"
    name     = "${var.project}.internal"
    vpc_id   = "${var.vpc_default_id}"
    tags {
        Environment = "${terraform.env}"
    }
}
resource "aws_route53_record" "registry" {
    provider = "aws.${var.region}"
    zone_id  = "${aws_route53_zone.internal.zone_id}"
    name     = "${terraform.env}-registry.${var.project}.internal"
    type     = "A"
    ttl      = "300"
    records  = ["${var.bastion_private_ip}"]
}

resource "aws_iam_access_key" "register_puller" {
    provider = "aws.${var.region}"
    user     = "${aws_iam_user.register_puller.name}"
}

resource "aws_iam_user" "register_puller" {
    provider = "aws.${var.region}"
    name     = "${terraform.env}-${var.project}-docker-register-puller"
    path     = "/system/"
}

resource "aws_iam_user_policy" "register_puller_role" {
    provider = "aws.${var.region}"
    name     = "${terraform.env}-${var.project}-docker-register-puller"
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
            "Resource": "${aws_s3_bucket.registry.arn}"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject"
            ],
            "Resource": "${aws_s3_bucket.registry.arn}/*"
        }
    ]
}
EOF
}

resource "aws_iam_access_key" "register_pusher" {
    provider = "aws.${var.region}"
    user     = "${aws_iam_user.register_pusher.name}"
}

resource "aws_iam_user" "register_pusher" {
    provider = "aws.${var.region}"
    name     = "${terraform.env}-${var.project}-docker-register-pusher"
    path     = "/system/"
}

resource "aws_iam_user_policy" "register_pusher_role" {
    provider = "aws.${var.region}"
    name     = "${terraform.env}-${var.project}-docker-register-pusher"
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
                "${aws_s3_bucket.registry.arn}",
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
                "${aws_s3_bucket.registry.arn}/*",
                "arn:aws:s3:::docker-env-config/*"
            ]
        }
    ]
}
EOF
}

resource "aws_s3_bucket" "registry" {
    provider = "aws.${var.region}"
    bucket = "registry.hub.internal"
    acl    = "private"
    lifecycle         = {
        ignore_changes  = "*"
        prevent_destroy = true
    }

    tags {
        Name        = "Registry"
        Environment = "${terraform.env}"
    }
}

resource "null_resource" "registry_trigger" {
    triggers {
        registry_id = "${aws_s3_bucket.registry.id}"
        record_name = "${aws_route53_record.registry.name}"
        bastion_ip  = "${var.bastion_public_ip}"
    }

    provisioner "remote-exec" {
        inline = [
            "docker rm -f registry_stg >/dev/null;docker run -d -e REGISTRY_STORAGE=s3 -e REGISTRY_STORAGE_S3_ACCESSKEY=${aws_iam_access_key.register_puller.id} -e REGISTRY_STORAGE_S3_SECRETKEY=${aws_iam_access_key.register_puller.secret} -e REGISTRY_STORAGE_S3_REGION=${var.region} -e REGISTRY_STORAGE_S3_REGIONENDPOINT=http://s3.${var.region}.amazonaws.com -e REGISTRY_STORAGE_S3_BUCKET=${aws_s3_bucket.registry.id} -e REGISTRY_STORAGE_S3_V4AUTH=true -e REGISTRY_STORAGE_S3_ROOTDIRECTORY=/ -p 80:5000 --name registry_stg --restart always registry:2",
        ]
        connection {
            type        = "ssh"
            user        = "ubuntu"
            host        = "${var.bastion_public_ip}"
            private_key = "${file("${path.root}${var.bastion_private_key_path}")}"
        }
    }
}

