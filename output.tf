output "wordpress-endpoint" {
  value = "http://${aws_instance.web.public_dns}/wordpress/wp-admin/install.php"
}

output "web-ip" {
  value = aws_instance.web.public_ip
}

output "db-address" {
  # value = "${aws_db_instance.public_ip}"
  value = aws_db_instance.default.address
}
