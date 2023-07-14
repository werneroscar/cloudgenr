# NETWORKING #
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = local.common_tags
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(local.common_tags, {
    description = "Internet Gateway for VPC"
  })
}

resource "aws_subnet" "public_subnet_lb" {
  cidr_block              = var.vpc_public_subnet_lb_cidr_block
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    description = "Public Subnet for LoadBalancer"
  })
}

resource "aws_subnet" "private_subnet_asg" {
  cidr_block              = var.vpc_private_subnet_asg_cidr_block
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = false

  tags = merge(local.common_tags, {
    description = "Private Subnet for ASG"
  })
}

resource "aws_subnet" "private_subnet_rds" {
  cidr_block              = var.vpc_private_subnet_rds_cidr_block
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = false

  tags = merge(local.common_tags, {
    description = "Private Subnet for RDS DB"
  })
}

# ROUTE TABLES #
resource "aws_route_table" "public-subnet-rtb" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(local.common_tags, {
    description = "Route table for LoadBalancer Public Subnet"
  })
}

resource "aws_route_table" "private-subnet-asg-rtb" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
  }
  route {
    cidr_block = var.vpc_private_subnet_asg_cidr_block
  }

  tags = merge(local.common_tags, {
    description = "Route table for Private Subnetfor ASG"
  })
}

resource "aws_route_table" "private_subnet_rds_rtb" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
  }
  route {
    cidr_block = var.vpc_private_subnet_asg_cidr_block
  }

  tags = merge(local.common_tags, {
    description = "Route table for LoadBalancer Private Subnet for RDS"
  })
}

# ROUTE TABLE ASSOCUATIONS #
resource "aws_route_table_association" "public-subnet-rta" {
  subnet_id      = aws_subnet.public_subnet_lb.id
  route_table_id = aws_route_table.public-subnet-rtb.id
}

resource "aws_route_table_association" "private-subnet-asg-rta" {
  subnet_id      = aws_subnet.private_subnet_asg.id
  route_table_id = aws_route_table.private-subnet-asg-rtb.id
}

resource "aws_route_table_association" "private-subnet-rds-rta" {
  subnet_id      = aws_subnet.private_subnet_rds.id
  route_table_id = aws_route_table.private_subnet_rds_rtb.id
}

## LoadBalancer ##
resource "aws_lb" "asg_lb" {
  name                             = "asg-lb"
  internal                         = false
  load_balancer_type               = "network"
  subnets                          = [var.vpc_private_subnet_asg_cidr_block]
  enable_cross_zone_load_balancing = true

  enable_deletion_protection = true

  tags = merge(local.common_tags, {
    description = "LoadBalancer for ASG"
  })
}

resource "aws_lb_target_group" "asg-lb-tg" {
  for_each = var.ports

  port     = each.value
  protocol = "TCP"
  vpc_id   = aws_vpc.vpc.id

  depends_on = [
    aws_lb.asg_lb
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_attachment" "asg-lb-tga" {
  for_each = var.ports

  autoscaling_group_name = aws_autoscaling_group.frontend-asg.name
  lb_target_group_arn    = aws_lb_target_group.asg-lb-tg[each.key].arn
}

resource "aws_lb_listener" "asg-lb-listener" {
  for_each = var.ports

  load_balancer_arn = aws_lb.asg_lb.arn

  protocol = "TCP"
  port     = each.value

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg-lb-tg[each.key].arn
  }
}

# SECURITY GROUPS #
# Nginx security group 
resource "aws_security_group" "nginx-sg" {
  name   = "nginx_sg"
  vpc_id = aws_vpc.vpc.id

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    description = "Security Group for ASG Instances"
  })
}

## Subnet Group for RDS DB ##
resource "aws_db_subnet_group" "asg-db-sg" {
  name       = "asg-db-sg"
  subnet_ids = [aws_subnet.private_subnet_rds.id]

  tags = merge(local.common_tags, {
    description = "Subnet Group for RDS DB"
  })
}