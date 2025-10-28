# -------------------------------------------------
# Database and Cache Configuration
# -------------------------------------------------

# -------------------------------------------------
# ElastiCache Security Group
# -------------------------------------------------
resource "aws_security_group" "elasticache" {
  name        = "elasticache-security-group"
  description = "Security group for ElastiCache Redis cluster"
  vpc_id      = aws_vpc.main.id

  # Inbound rules: Allow Redis traffic from ECS service
  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_service.id]
    description     = "Redis traffic from ECS service"
  }

  # No egress rules needed (Redis is outbound only)

  tags = {
    Name = "colyseus-elasticache-sg"
  }
}

# Note: VPC endpoints security group already exists in endpoint.tf
# We'll reuse the existing aws_security_group.vpc_endpoints from endpoint.tf

# -------------------------------------------------
# ElastiCache Redis Subnet Group
# -------------------------------------------------
resource "aws_elasticache_subnet_group" "main" {
  name       = "colyseus-redis-subnet-group"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_c.id]

  tags = {
    Name = "colyseus-redis-subnet-group"
  }
}

# -------------------------------------------------
# ElastiCache Redis Cluster
# -------------------------------------------------
resource "aws_elasticache_replication_group" "main" {
  replication_group_id       = "colyseus-redis-cluster"
  description                = "Redis cluster for Colyseus game state management"
  engine                     = "redis"
  engine_version             = "7.0"
  node_type                  = "cache.t4g.micro"
  port                       = 6379
  parameter_group_name       = "default.redis7"
  automatic_failover_enabled = true
  multi_az_enabled           = true
  num_cache_clusters         = 2  # Primary + replica for high availability

  subnet_group_name = aws_elasticache_subnet_group.main.name
  security_group_ids = [aws_security_group.elasticache.id]

  # Maintenance window: Sundays 3:00-5:00 AM UTC (JST-friendly time)
  maintenance_window = "sun:03:00-sun:05:00"

  # Snapshot window: Daily backups at 5:30-6:30 AM UTC (no overlap with maintenance)
  snapshot_window = "05:30-06:30"
  snapshot_retention_limit = 7  # Keep 7 days of snapshots

  tags = {
    Name = "colyseus-redis-cluster"
    Project = "colyseus-portfolio"
  }
}

# -------------------------------------------------
# DynamoDB Tables
# -------------------------------------------------

# Users table for player profiles and authentication
resource "aws_dynamodb_table" "users" {
  name           = "colyseus-users"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "user_id"
  range_key      = "sort_key"

  attribute {
    name = "user_id"
    type = "S"
  }

  attribute {
    name = "sort_key"
    type = "S"
  }

  attribute {
    name = "email"
    type = "S"
  }

  attribute {
    name = "username"
    type = "S"
  }

  global_secondary_index {
    name     = "EmailIndex"
    hash_key = "email"
    projection_type = "ALL"
  }

  global_secondary_index {
    name     = "UsernameIndex"
    hash_key = "username"
    projection_type = "ALL"
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name = "colyseus-users-table"
    Project = "colyseus-portfolio"
  }
}

# Game sessions table for active game state
resource "aws_dynamodb_table" "game_sessions" {
  name           = "colyseus-game-sessions"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "room_id"
  range_key      = "session_key"

  attribute {
    name = "room_id"
    type = "S"
  }

  attribute {
    name = "session_key"
    type = "S"
  }

  attribute {
    name = "game_type"
    type = "S"
  }

  attribute {
    name = "created_at"
    type = "N"
  }

  attribute {
    name = "status"
    type = "S"
  }

  global_secondary_index {
    name     = "GameTypeIndex"
    hash_key = "game_type"
    range_key = "created_at"
    projection_type = "ALL"
  }

  global_secondary_index {
    name     = "StatusIndex"
    hash_key = "status"
    range_key = "created_at"
    projection_type = "ALL"
  }

  point_in_time_recovery {
    enabled = true
  }

  ttl {
    attribute_name = "expires_at"
    enabled = true
  }

  tags = {
    Name = "colyseus-game-sessions-table"
    Project = "colyseus-portfolio"
  }
}

# Game history table for completed games and statistics
resource "aws_dynamodb_table" "game_history" {
  name           = "colyseus-game-history"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "game_id"

  attribute {
    name = "game_id"
    type = "S"
  }

  attribute {
    name = "player_id"
    type = "S"
  }

  attribute {
    name = "game_type"
    type = "S"
  }

  attribute {
    name = "completed_at"
    type = "N"
  }

  global_secondary_index {
    name     = "PlayerIndex"
    hash_key = "player_id"
    range_key = "completed_at"
    projection_type = "ALL"
  }

  global_secondary_index {
    name     = "GameTypeIndex"
    hash_key = "game_type"
    range_key = "completed_at"
    projection_type = "ALL"
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name = "colyseus-game-history-table"
    Project = "colyseus-portfolio"
  }
}

# -------------------------------------------------
# VPC Endpoints for Private Connectivity
# -------------------------------------------------

# VPC Gateway Endpoint for DynamoDB
resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.ap-northeast-1.dynamodb"
  route_table_ids = [
    aws_route_table.private.id,
  ]

  tags = {
    Name = "colyseus-dynamodb-vpc-endpoint"
    Project = "colyseus-portfolio"
  }
}

# VPC Interface Endpoint for ElastiCache (if needed for future use)
# Note: ElastiCache is typically accessed through private subnets directly,
# but we can add this if needed for specific use cases

# -------------------------------------------------
# IAM Policies for Data Service Access
# -------------------------------------------------

# IAM Policy for DynamoDB access
resource "aws_iam_policy" "dynamodb_access" {
  name        = "colyseus-dynamodb-access-policy"
  description = "IAM policy for Colyseus to access DynamoDB tables"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:BatchGetItem",
          "dynamodb:BatchWriteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = [
          aws_dynamodb_table.users.arn,
          aws_dynamodb_table.game_sessions.arn,
          aws_dynamodb_table.game_history.arn,
          "${aws_dynamodb_table.users.arn}/*",
          "${aws_dynamodb_table.game_sessions.arn}/*",
          "${aws_dynamodb_table.game_history.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:DescribeTable",
          "dynamodb:ListTables"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name = "colyseus-dynamodb-access-policy"
    Project = "colyseus-portfolio"
  }
}

# IAM Policy for ElastiCache access
resource "aws_iam_policy" "elasticache_access" {
  name        = "colyseus-elasticache-access-policy"
  description = "IAM policy for Colyseus to access ElastiCache Redis"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticache:DescribeCacheClusters",
          "elasticache:DescribeReplicationGroups",
          "elasticache:ListAllowedNodeTypeModifications"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name = "colyseus-elasticache-access-policy"
    Project = "colyseus-portfolio"
  }
}

# Attach policies to ECS task role
resource "aws_iam_role_policy_attachment" "ecs_task_dynamodb" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.dynamodb_access.arn
}

resource "aws_iam_role_policy_attachment" "ecs_task_elasticache" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.elasticache_access.arn
}