output "secret" {
    value = "${aws_iam_access_key.register_puller.secret}"
}
output "access" {
    value = "${aws_iam_access_key.register_puller.id}"
}
