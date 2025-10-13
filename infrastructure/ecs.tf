# -------------------------------------------------
# IAM 角色 - 赋予ECS服务执行操作的权限
# -------------------------------------------------
# 1. 任务执行角色 (Task Execution Role)
#    这个角色是ECS Agent用来拉取ECR镜像和发送日志到CloudWatch的。
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs-task-execution-role"

  # assume_role_policy定义了谁可以扮演这个角色，这里是ECS任务
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# 为任务执行角色附加AWS托管的策略
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# 2. 任务角色 (Task Role) - 可选，但建议创建
#    这个角色是容器内的应用程序本身用来调用其他AWS服务的。
#    现在它还是空的，但第三周会为它添加访问Redis和DynamoDB的权限。
resource "aws_iam_role" "ecs_task_role" {
  name = "ecs-task-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# -------------------------------------------------
# ECS 集群 - 运行所有服务的逻辑分组
# -------------------------------------------------
resource "aws_ecs_cluster" "main" {
  name = "colyseus-cluster"
}

# -------------------------------------------------
# CloudWatch 日志组 - 存放容器的日志
# -------------------------------------------------
resource "aws_cloudwatch_log_group" "colyseus_logs" {
  name = "/ecs/colyseus-app"
  retention_in_days = 7 # 日志保留7天
}

# -------------------------------------------------
# ECS 任务定义 - 运行容器的“蓝图”
# -------------------------------------------------
resource "aws_ecs_task_definition" "colyseus_app" {
  family                   = "colyseus-app"
  network_mode             = "awsvpc" # Fargate必须使用awsvpc模式
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"  # 0.25 vCPU
  memory                   = "512"  # 512 MB RAM
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  # 容器定义 (JSON格式)
  container_definitions = jsonencode([
    {
      name      = "colyseus-app-container",
      # ECR镜像URI
      image     = "986341372185.dkr.ecr.ap-northeast-1.amazonaws.com/colyseus-app:latest",
      portMappings = [
        {
          containerPort = 2567,
          hostPort      = 2567
        }
      ],
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.colyseus_logs.name,
          "awslogs-region"        = "ap-northeast-1",
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

# -------------------------------------------------
# 安全组 - 容器的“防火墙”
# -------------------------------------------------
resource "aws_security_group" "ecs_service" {
  name        = "ecs-service-sg"
  description = "Security group for Colyseus ECS service"
  vpc_id      = aws_vpc.main.id

  # 出站规则: 允许容器访问外部网络 (例如拉取镜像或调用外部API)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "colyseus-ecs-sg"
  }
}

# -------------------------------------------------
# ECS 服务 - 确保的任务定义一直按要求运行
# -------------------------------------------------
resource "aws_ecs_service" "main" {
  name            = "colyseus-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.colyseus_app.arn
  desired_count   = 1 # 希望一直保持1个任务在运行
  launch_type     = "FARGATE"

  network_configuration {
    # 在创建的私有子网中运行任务
    subnets         = [aws_subnet.private_a.id, aws_subnet.private_c.id]
    security_groups = [aws_security_group.ecs_service.id]
  }

  # 忽略任务定义的小版本变更，以便CI/CD可以平滑更新
  lifecycle {
    ignore_changes = [task_definition]
  }
}