##################################################################################
# DATA
##################################################################################

data "aws_ssm_parameter" "ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

##################################################################################
# RESOURCES
##################################################################################

# INSTANCES #
resource "aws_placement_group" "asg-placement-group" {
  name     = "asg-placement-group"
  strategy = "cluster"
}

resource "aws_launch_configuration" "asg-launch-configuration" {
  name          = "frontend_launch_configuration"
  image_id      = data.aws_ssm_parameter.ami.id
  instance_type = var.instance_type
  user_data     = <<EOF
    #! /bin/bash
    sudo amazon-linux-extras install -y nginx1
    sudo service nginx start
    sudo rm /usr/share/nginx/html/index.html
    echo '<html><head><title>Taco Team Server</title></head><body style=\"background-color:#1F778D\"><p style=\"text-align: center;\"><span style=\"color:#FFFFFF;\"><span style=\"font-size:28px;\">You did it! Have a &#127790;</span></span></p></body></html>' | sudo tee /usr/share/nginx/html/index.html
    EOF
}

resource "aws_autoscaling_group" "frontend-asg" {
  name                      = "frontend-asg"
  max_size                  = 3
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 4
  force_delete              = true
  placement_group           = aws_placement_group.asg-placement-group.id
  launch_configuration      = aws_launch_configuration.asg-launch-configuration.name
  vpc_zone_identifier       = [aws_subnet.private_subnet_asg.id]
  depends_on                = [aws_db_instance.asg-database]

  #   initial_lifecycle_hook {
  #     name                 = "foobar"
  #     default_result       = "CONTINUE"
  #     heartbeat_timeout    = 2000
  #     lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"

  #     notification_metadata = jsonencode({
  #       autoscale = "bar"
  #     })

  #     notification_target_arn = "arn:aws:sqs:us-east-1:444455556666:queue1*"
  #     role_arn                = aws_iam_role.asg-database-role
  #   }

  tag {
    key                 = "instance"
    value               = "Frontend ASG Instance"
    propagate_at_launch = true
  }

  timeouts {
    delete = "15m"
  }

  #   tags = merge(local.common_tags, {
  #     description = "Frontend ASG"
  #   })
}

resource "aws_iam_role" "asg-database-role" {
  name = "asg-database-role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
      },
    ]
  })

  tags = merge(local.common_tags, {
    description = "ASG Role"
  })
}



