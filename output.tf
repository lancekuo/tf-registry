output "secret" {
    value = "${aws_iam_access_key.register_puller.secret}"
}
output "access" {
    value = "${aws_iam_access_key.register_puller.id}"
}
output "registry_internal_dns" {
    value = "${aws_route53_record.registry.fqdn}"
}
output "registry_bucket_id" {
    value = "${aws_s3_bucket.registry.id}"
}
