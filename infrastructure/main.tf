terraform {
  # 在这里声明我们这个项目需要哪些插件
  required_providers {
    # 声明需要HashiCorp官方的AWS Provider
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # 锁定AWS Provider的主版本为5.x，防止未来自动更新引入破坏性变更
    }
  }
}

# 针对使用的AWS Provider进行具体配置
provider "aws" {
  # 指定所有资源默认创建在哪个AWS区域
  region = "ap-northeast-1"
}