output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnets" {
  value = aws_subnet.public[*].id
}

output "private_subnets" {
  value = aws_subnet.private[*].id
}

output "alb_dns" {
  value = aws_lb.app_alb.dns_name
}

output "ec2_ids" {
  value = aws_instance.app[*].id
}

output "s3_bucket" {
  value = aws_s3_bucket.html_bucket.id
}
