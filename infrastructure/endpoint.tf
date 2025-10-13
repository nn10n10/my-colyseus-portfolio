# ECR需要两个接口端点(Interface Endpoints)来拉取镜像
# 以及一个S3的网关端点(Gateway Endpoint)来下载镜像层

# 为端点创建一个专门的安全组
resource "aws_security_group" "vpc_endpoints" {
  name   = "vpc-endpoints-sg"
  vpc_id = aws_vpc.main.id

  # 允许VPC内的所有流量访问这些端点
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }
}

# 1. ECR API 接口端点 (用于认证) 
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.ap-northeast-1.ecr.api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.private_a.id, aws_subnet.private_c.id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
}

# 2. ECR DKR 接口端点 (用于拉取镜像数据)
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.ap-northeast-1.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.private_a.id, aws_subnet.private_c.id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
}

# 3. S3 网关端点 (ECR使用S3存储镜像)
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.ap-northeast-1.s3"
  vpc_endpoint_type = "Gateway"
  # 将这个端点关联到私有子网的路由表上
  # (需要为私有子网也创建一个路由表)
}

# 需要为私有子网也创建路由表并关联
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "colyseus-private-rt"
  }
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_c" {
  subnet_id      = aws_subnet.private_c.id
  route_table_id = aws_route_table.private.id
}