data "aws_ami" "amazon_linux" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name = "name"

    values = [
      "al2023-ami-2023.*-x86_64"
    ]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# --------------------------------------------------
# Launch Template
# --------------------------------------------------

resource "aws_launch_template" "main" {
  name_prefix = "${var.project_name}-${var.environment}-"

  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  vpc_security_group_ids = [
    var.ec2_security_group_id
  ]

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

 user_data = base64encode(<<EOF
#!/bin/bash

dnf install -y nginx

systemctl enable nginx
systemctl start nginx

TOKEN=$(curl -X PUT \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" \
  -s http://169.254.169.254/latest/api/token)

INSTANCE_ID=$(curl \
  -H "X-aws-ec2-metadata-token: $TOKEN" \
  -s http://169.254.169.254/latest/meta-data/instance-id)

PRIVATE_IP=$(curl \
  -H "X-aws-ec2-metadata-token: $TOKEN" \
  -s http://169.254.169.254/latest/meta-data/local-ipv4)

AZ=$(curl \
  -H "X-aws-ec2-metadata-token: $TOKEN" \
  -s http://169.254.169.254/latest/meta-data/placement/availability-zone)

cat > /usr/share/nginx/html/index.html <<HTML
<!DOCTYPE html>
<html>

<head>
  <title>Terraform AWS HTML Application</title>

  <style>
    body {
      font-family: Arial, sans-serif;
      background: #f3f4f6;
      text-align: center;
      padding-top: 80px;
    }

    .container {
      background: white;
      width: 650px;
      margin: auto;
      padding: 40px;
      border-radius: 12px;
      box-shadow: 0 5px 20px rgba(0,0,0,0.15);
    }

    h1 {
      color: #232f3e;
    }

    .info {
      margin-top: 25px;
      padding: 20px;
      background: #eef2ff;
      border-radius: 8px;
    }
  </style>
</head>

<body>

  <div class="container">

    <h1>AWS Terraform Application</h1>

    <h2>Application is running successfully!</h2>

    <div class="info">

      <p><strong>Instance ID:</strong> $INSTANCE_ID</p>

      <p><strong>Private IP:</strong> $PRIVATE_IP</p>

      <p><strong>Availability Zone:</strong> $AZ</p>

      <p><strong>Deployment:</strong> Auto Scaling Group</p>

      <p><strong>Network:</strong> Private Subnet</p>

    </div>

  </div>

</body>

</html>
HTML

systemctl restart nginx
EOF
)

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name        = "${var.project_name}-${var.environment}-web"
      Environment = var.environment
      Project     = var.project_name
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# --------------------------------------------------
# Auto Scaling Group
# --------------------------------------------------

resource "aws_autoscaling_group" "main" {
  name = "${var.project_name}-${var.environment}-asg"

  min_size         = var.min_size
  desired_capacity = var.desired_capacity
  max_size         = var.max_size

  vpc_zone_identifier = var.private_subnet_ids

  target_group_arns = [
    var.target_group_arn
  ]

  health_check_type         = "ELB"
  health_check_grace_period = 180

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-web"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }
}

# --------------------------------------------------
# CPU Auto Scaling
# --------------------------------------------------

resource "aws_autoscaling_policy" "cpu" {
  name = "${var.project_name}-${var.environment}-cpu-policy"

  autoscaling_group_name = aws_autoscaling_group.main.name

  policy_type = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 60
  }
}