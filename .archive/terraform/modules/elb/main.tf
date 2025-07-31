# Creates an Elastic Load Balancer in the VPC/subnet specified
# - Allows ingress traffic on ports 80 and 443 only
# - Supports Istio health checking and SNI in the cluster
# - Maps to node ports in cluster
# - Security group created for other entities to use for ingress from the ELB
# - Attaching a pool to the load balancer is done outside of this Terraform

resource "aws_lb" "public_nlb" {
  name               = "${var.name}-public-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = var.subnet_ids

  tags = merge({}, var.tags)
}

resource "aws_lb_target_group" "public_nlb_http" {
  name     = "${var.name}-public-nlb-http"
  port     = var.node_port_http
  protocol = "TCP"
  vpc_id   = var.vpc_id

  health_check {
    port = var.node_port_health_checks
    path = "/healthz/ready"
  }
  lifecycle {
    create_before_destroy = true
  }
  tags = merge({}, var.tags)
}

resource "aws_lb_target_group" "public_nlb_https" {
  name     = "${var.name}-public-nlb-https"
  port     = var.node_port_https
  protocol = "TCP"
  vpc_id   = var.vpc_id

  health_check {
    port = var.node_port_health_checks
    path = "/healthz/ready"
  }
  lifecycle {
    create_before_destroy = true
  }
  tags = merge({}, var.tags)
}

resource "aws_lb_target_group" "public_nlb_sni" {
  name     = "${var.name}-public-nlb-sni"
  port     = var.node_port_sni
  protocol = "TCP"
  vpc_id   = var.vpc_id

  health_check {
    port = var.node_port_health_checks
    path = "/healthz/ready"
  }
  lifecycle {
    create_before_destroy = true
  }
  tags = merge({}, var.tags)
}

resource "aws_lb_listener" "public_nlb_http" {
  load_balancer_arn = aws_lb.public_nlb.arn
  port              = "80"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.public_nlb_http.arn
  }
}

resource "aws_lb_listener" "public_nlb_https" {
  load_balancer_arn = aws_lb.public_nlb.arn
  port              = "443"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.public_nlb_https.arn
  }
}

resource "aws_lb_listener" "public_nlb_sni" {
  load_balancer_arn = aws_lb.public_nlb.arn
  port              = "15443"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.public_nlb_sni.arn
  }
}

# Retrieve the IP addresses of the nlb
data "aws_network_interface" "public_nlb" {
  for_each = toset(var.subnet_ids)

  filter {
    name   = "description"
    values = ["ELB ${aws_lb.public_nlb.arn_suffix}"]
  }

  filter {
    name   = "subnet-id"
    values = [each.value]
  }
}

# Security group for server pool to allow traffic from load balancer
resource "aws_security_group" "public_nlb_pool" {
  name_prefix = "${var.name}-public-nlb-to-pool-"
  description = "${var.name} Traffic from public Network Load Balancer to server pool"
  vpc_id      = var.vpc_id

  # Allow all traffic from load balancer
  ingress {
    description = "Allow public Network Load Balancer traffic to health check"
    from_port   = var.node_port_health_checks
    to_port     = var.node_port_health_checks
    protocol    = "tcp"
    cidr_blocks = formatlist("%s/32", [for eni in data.aws_network_interface.public_nlb : eni.private_ip])
  }

  ingress {
    description = "Allow internet traffic to HTTP node port"
    from_port   = var.node_port_http
    to_port     = var.node_port_http
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow internet traffic to HTTPS node port"
    from_port   = var.node_port_https
    to_port     = var.node_port_https
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow internet traffic to SNI node port"
    from_port   = var.node_port_sni
    to_port     = var.node_port_sni
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}