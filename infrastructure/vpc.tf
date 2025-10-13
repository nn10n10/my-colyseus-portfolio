# -------------------------------------------------
# VPC - 数字私人土地
# -------------------------------------------------
resource "aws_vpc" "main" {
  # CIDR地址块，定义了VPC的IP地址范围
  cidr_block = "10.0.0.0/16"

  # 为VPC启用DNS主机名，这样AWS可以为资源分配公共DNS
  enable_dns_hostnames = true
  enable_dns_support   = true

  # 为的资源添加标签，方便识别和管理
  tags = {
    Name = "colyseus-vpc"
  }
}

# -------------------------------------------------
# 子网 - 在土地上划分出不同的功能区域
# -------------------------------------------------
# 公共子网1 (用于放置ALB等需要面向公网的服务)
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-1a" # 东京区域的可用区a
  map_public_ip_on_launch = true # 在这个子网启动的资源会自动分配公网IP

  tags = {
    Name = "colyseus-public-a"
  }
}

# 公共子网2 (放在另一个可用区，实现高可用)
resource "aws_subnet" "public_c" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-northeast-1c" # 东京区域的可用区c
  map_public_ip_on_launch = true

  tags = {
    Name = "colyseus-public-c"
  }
}

# 私有子网1 (用于放置ECS任务、数据库等核心服务)
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "colyseus-private-a"
  }
}

# 私有子网2 (放在另一个可用区，实现高可用)
resource "aws_subnet" "private_c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "ap-northeast-1c"

  tags = {
    Name = "colyseus-private-c"
  }
}

# -------------------------------------------------
# 互联网网关 & 路由 - 连接外部世界
# -------------------------------------------------
# 创建一个互联网网关，作为VPC连接到互联网的出口
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "colyseus-igw"
  }
}

# 创建一个路由表，定义公共子网的流量规则
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  # 定义一条路由规则：所有去往外部互联网(0.0.0.0/0)的流量，
  # 都从上面创建的互联网网关出去。
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "colyseus-public-rt"
  }
}

# 将创建的两个公共子网，关联到这个公共路由表上
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_c" {
  subnet_id      = aws_subnet.public_c.id
  route_table_id = aws_route_table.public.id
}