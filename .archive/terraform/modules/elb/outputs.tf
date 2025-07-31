output "pool_sg_id" {
  description = "The ID of the security group used as an inbound rule for load balancer's back-end server pool"
  value       = aws_security_group.public_nlb_pool.id
}

output "elb_target_group_arns" {
  description = "The load balancer target group ARNs"
  value       = [aws_lb_target_group.public_nlb_http.arn, aws_lb_target_group.public_nlb_https.arn, aws_lb_target_group.public_nlb_sni.arn]
}