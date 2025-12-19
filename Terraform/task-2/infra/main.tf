provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {}

# ---- VPC ----
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "nti-vpc" }
}

# ---- Public Subnets ----
resource "aws_subnet" "public" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = { Name = "nti-public-${count.index + 1}" }
}

# ---- Private Subnets ----
resource "aws_subnet" "private" {
  count                   = length(var.private_subnets)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnets[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false
  tags = { Name = "nti-private-${count.index + 1}" }
}

# ---- S3 Bucket ----
resource "aws_s3_bucket" "html_bucket" {
  bucket = var.s3_bucket_name
  acl    = "private"

  versioning { enabled = true }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = { Name = "NTI HTML Bucket" }
}

# ---- IAM Policy for ALB service-linked role to read S3 ----
data "aws_iam_policy_document" "alb_s3_read" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.html_bucket.arn}/*"]
    effect    = "Allow"
  }
}

resource "aws_iam_policy" "alb_s3_policy" {
  name   = "alb-s3-read-policy"
  policy = data.aws_iam_policy_document.alb_s3_read.json
}

# ---- Attach Policy to ALB service-linked role ----
resource "aws_iam_role_policy_attachment" "alb_attach" {
  role       = "AWSServiceRoleForElasticLoadBalancing"
  policy_arn = aws_iam_policy.alb_s3_policy.arn
}

# ---- Security Groups ----
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  vpc_id      = aws_vpc.main.id
  description = "Allow HTTP from anywhere"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ec2_sg" {
  name        = "ec2-sg"
  vpc_id      = aws_vpc.main.id
  description = "Allow HTTP from ALB only"

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---- EC2 Instances ----
resource "aws_instance" "app" {
  count                 = length(var.private_subnets)
  ami                   = var.ami_id
  instance_type         = var.instance_type
  subnet_id             = aws_subnet.private[count.index].id
  security_groups       = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = false

  user_data = file("${path.module}/apache_setup.sh")

  tags = { Name = "nti-app-${count.index + 1}" }
}

# ---- ALB ----
resource "aws_lb" "app_alb" {
  name               = var.alb_name
  load_balancer_type = "application"
  subnets            = [aws_subnet.public[1].id]
  security_groups    = [aws_security_group.alb_sg.id]
}

# ---- Target Group ----
resource "aws_lb_target_group" "app_tg" {
  name     = "nti-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  target_type = "instance"
}

resource "aws_lb_target_group_attachment" "app_attachment" {
  count            = length(aws_instance.app)
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = aws_instance.app[count.index].id
  port             = 80
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}
