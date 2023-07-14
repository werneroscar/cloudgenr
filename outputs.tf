output "loadbalancer_ip" {
  value = aws_lb.asg_lb.zone_id
}

output "loadbalancer_dns" {
  value = aws_lb.asg_lb.dns_name
}