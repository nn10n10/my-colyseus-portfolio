# Project Context

## Purpose

This is a personal portfolio project demonstrating production-grade deployment of the **Colyseus real-time multiplayer game server** on **AWS cloud** using Infrastructure as Code (IaC) and CI/CD practices. The project showcases:

- Building reproducible, automated cloud-native systems
- Implementing high availability, scalability, security, and cost-effectiveness
- Demonstrating expertise in modern cloud architecture and DevOps practices
- Creating a reference implementation for real-time gaming backends

## Tech Stack

### Core Technologies
- **Application Framework**: Colyseus (Node.js, TypeScript) - Real-time multiplayer game server
- **Containerization**: Docker - Application packaging
- **Container Registry**: Amazon ECR - Private image repository
- **Container Orchestration**: Amazon ECS on AWS Fargate - Serverless container execution
- **Infrastructure as Code**: Terraform - Declarative infrastructure management
- **CI/CD**: GitHub Actions - Build, test, and deployment automation
- **Cloud Platform**: AWS (Amazon Web Services) - Primary cloud platform

### AWS Services
- **Networking**: VPC, Application Load Balancer, CloudFront, AWS WAF & Shield
- **Compute**: ECS Fargate, Auto Scaling Groups
- **Data Storage**: ElastiCache (Redis), DynamoDB
- **Monitoring & Logging**: Amazon CloudWatch (Logs, Metrics, Alarms)
- **Security**: IAM, Secrets Manager, Security Groups
- **Content Delivery**: S3 (for static assets)

## Project Conventions

### Code Style
- **TypeScript**: Strict mode enabled for type safety
- **Node.js**: Modern ES6+ features, async/await patterns
- **Terraform**: HCL formatted with consistent naming conventions
  - Resources: kebab-case (e.g., `colyseus-vpc`, `ecs-service-sg`)
  - Variables: snake_case with descriptions
  - Outputs: camelCase for consumption by other modules
- **Docker**: Multi-stage builds, minimal base images
- **File Naming**: kebab-case for files and directories

### Architecture Patterns
- **Serverless First**: Prefer AWS Fargate over EC2 when possible
- **Infrastructure as Code**: All infrastructure managed through Terraform
- **Microservices**: Single responsibility per service/container
- **Event-Driven**: Asynchronous communication patterns where appropriate
- **Security by Default**: Private subnets, least privilege IAM roles, encryption at rest and in transit

### Testing Strategy
- **Unit Tests**: Jest for TypeScript application logic
- **Integration Tests**: End-to-end testing for game room functionality
- **Infrastructure Tests**: Terraform validate and plan verification
- **Load Testing**: Custom load testing scripts for multiplayer scenarios
- **Security Tests**: Automated security scanning for containers and infrastructure

### Git Workflow
- **Main Branch**: `master` - Production-ready code only
- **Feature Branches**: `feature/feature-name` - Descriptive naming
- **Commit Messages**: Conventional Commits format (`feat:`, `fix:`, `docs:`, etc.)
- **Pull Requests**: Required for all changes with automated checks
- **Release Tags**: Semantic versioning (`v1.0.0`, `v1.1.0`, etc.)

## Domain Context

### Gaming Domain Knowledge
- **Real-time Multiplayer**: Low-latency communication is critical (<100ms)
- **State Synchronization**: Game state must be consistent across all clients
- **Room Management**: Dynamic creation/destruction of game sessions
- **Scalability**: Handle variable player loads with auto-scaling
- **Matchmaking**: Player grouping and lobby management

### Cloud Architecture Context
- **Multi-AZ Deployment**: High availability across multiple availability zones
- **Private Network**: Application servers in private subnets for security
- **VPC Endpoints**: Private connectivity to AWS services without internet access
- **Auto Scaling**: Automatic scaling based on CPU/memory metrics and player count
- **CDN Integration**: Static assets delivered via CloudFront for global performance

## Important Constraints

### Technical Constraints
- **Region**: Deployed in `ap-northeast-1` (Tokyo) for low latency in Asian markets
- **Performance**: Target <100ms latency for real-time game communication
- **Availability**: 99.9% uptime requirement with Multi-AZ deployment
- **Scalability**: Must support 1000+ concurrent players with auto-scaling
- **Security**: All traffic encrypted, no direct internet access to application servers

### Business Constraints
- **Cost Optimization**: Use serverless and pay-as-you-go services to minimize costs
- **Learning Focus**: Prioritize educational value and skill demonstration over optimization
- **Portfolio Quality**: Production-ready implementation with proper monitoring and security

### Regulatory Constraints
- **Data Privacy**: Player data handled according to privacy best practices
- **Security Compliance**: Follow AWS security best practices and guidelines

## External Dependencies

### AWS Services
- **ECR**: Container image registry (`986341372185.dkr.ecr.ap-northeast-1.amazonaws.com/colyseus-app`)
- **ECS**: Container orchestration and management
- **ElastiCache**: Redis for session state and real-time data
- **DynamoDB**: NoSQL database for persistent game data
- **CloudWatch**: Logging, monitoring, and alerting
- **Secrets Manager**: Secure credential storage

### Third-Party Services
- **Colyseus**: Open-source multiplayer game server framework
- **Node.js**: JavaScript runtime environment
- **TypeScript**: Type-safe JavaScript superset
- **Docker Hub**: Base images and container tools

### Development Tools
- **GitHub**: Source code repository and CI/CD pipelines
- **Terraform Cloud**: Infrastructure state management and collaboration
- **VS Code**: Primary development environment with extensions for TypeScript, Docker, and Terraform
