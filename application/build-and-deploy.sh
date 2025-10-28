#!/bin/bash

# Phase 3 应用构建和部署脚本
set -e

echo "🔨 Phase 3 应用构建和部署开始..."

# 检查是否在正确的目录
if [ ! -f "package.json" ]; then
    echo "❌ 错误: 请在 application 目录中运行此脚本"
    exit 1
fi

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "\n${YELLOW}1. 安装依赖...${NC}"
npm install

echo -e "\n${YELLOW}2. 构建TypeScript应用...${NC}"
npm run build

echo -e "\n${YELLOW}3. 验证配置...${NC}"
# 运行配置验证（模拟环境变量）
export AWS_REGION="ap-northeast-1"
export REDIS_HOST="test-host"
export REDIS_PORT="6379"
export USERS_TABLE="colyseus-users"
export GAME_SESSIONS_TABLE="colyseus-game-sessions"
export GAME_HISTORY_TABLE="colyseus-game-history"
export PORT="2567"
export NODE_ENV="production"

# 检查构建是否成功
if [ -d "build" ]; then
    echo -e "${GREEN}✅ TypeScript 构建成功${NC}"
else
    echo -e "${RED}❌ TypeScript 构建失败${NC}"
    exit 1
fi

echo -e "\n${YELLOW}4. 构建Docker镜像...${NC}"
ECR_REGISTRY="986341372185.dkr.ecr.ap-northeast-1.amazonaws.com"
IMAGE_NAME="colyseus-app"
IMAGE_TAG="phase3"

echo "构建镜像: $ECR_REGISTRY/$IMAGE_NAME:$IMAGE_TAG"
docker build -t $ECR_REGISTRY/$IMAGE_NAME:$IMAGE_TAG .
docker tag $ECR_REGISTRY/$IMAGE_NAME:$IMAGE_TAG $ECR_REGISTRY/$IMAGE_NAME:latest

echo -e "\n${YELLOW}5. 推送到ECR...${NC}"
# 登录ECR
aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin $ECR_REGISTRY

# 推送镜像
docker push $ECR_REGISTRY/$IMAGE_NAME:$IMAGE_TAG
docker push $ECR_REGISTRY/$IMAGE_NAME:latest

echo -e "\n${GREEN}🎉 Phase 3 应用构建和部署完成！${NC}"
echo -e "${GREEN}📦 镜像已推送到: $ECR_REGISTRY/$IMAGE_NAME:$IMAGE_TAG${NC}"
echo -e "\n${YELLOW}下一步:${NC}"
echo "1. 执行 'cd ../infrastructure && terraform apply' 部署基础设施"
echo "2. 验证部署: curl http://<ALB-DNS>/health"
echo "3. 检查日志: aws logs tail /ecs/colyseus-app --follow"