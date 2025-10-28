# -------------------------------------------------
# Load Balancer Configuration
# -------------------------------------------------

# -------------------------------------------------
# Application Load Balancer Security Group
# -------------------------------------------------
resource "aws_security_group" "alb" {
  name        = "alb-security-group"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  # Inbound rules: Allow HTTP and HTTPS traffic from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP traffic from anywhere"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS traffic from anywhere (for Phase 4)"
  }

  # Outbound rules: Allow traffic to ECS service
  egress {
    from_port       = 2567
    to_port         = 2567
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_service.id]
    description     = "Traffic to ECS service"
  }

  tags = {
    Name = "colyseus-alb-sg"
  }
}

# -------------------------------------------------
# Update ECS Service Security Group to allow traffic from ALB
# -------------------------------------------------
resource "aws_security_group_rule" "ecs_from_alb" {
  type                     = "ingress"
  from_port                = 2567
  to_port                  = 2567
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ecs_service.id
  source_security_group_id = aws_security_group.alb.id
  description              = "Allow traffic from ALB"
}

# -------------------------------------------------
# Application Load Balancer
# -------------------------------------------------
resource "aws_lb" "main" {
  name               = "colyseus-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_c.id]

  enable_deletion_protection = false

  tags = {
    Name = "colyseus-alb"
    Project = "colyseus-portfolio"
  }
}

# Target Group for ECS Service
resource "aws_lb_target_group" "main" {
  name     = "colyseus-tg"
  port     = 2567
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"  # Basic health check endpoint
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  # Deregistration delay to give time for graceful shutdown
  deregistration_delay = 30

  tags = {
    Name = "colyseus-target-group"
    Project = "colyseus-portfolio"
  }
}

# ALB Listener for HTTP
resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  tags = {
    Name = "colyseus-listener-http"
    Project = "colyseus-portfolio"
  }
}