[日本語](#japanese) | [English](#english)

<div id="japanese">

# 🎮 Colyseus on AWS: 本番環境レベルの IaC / CI/CD ポートフォリオ

## 1. プロジェクト概要 

このプロジェクトは、リアルタイム多人数参加型ゲームサーバーである **[Colyseus](https://www.colyseus.io/)** を、  
**AWS クラウド上で本番環境レベルの品質で稼働** させることを目的とした個人ポートフォリオです。

**Infrastructure as Code (Terraform)** と **CI/CD (GitHub Actions)** のプラクティスを全面的に採用し、  
高可用性、スケーラビリティ、セキュリティ、そしてコスト効率に優れた、  
**再現可能かつ自動化されたクラウドネイティブなシステム** を構築するプロセスを実証します。

---

## 2. 目標アーキテクチャ 

以下は本プロジェクトが最終的に目指すシステムの全体構成図です。  
ユーザーリクエストの入口からデータストレージまで、多層防御と Multi-AZ による高可用性を考慮した設計です。

```mermaid
graph TD
    %% (前面省略的节点定义 A..M 保持不变)
    A((User / Game Client))
    B[🛡AWS WAF & Shield<br>DDoS & Attack Protection]
    C[CloudFront CDN]
    D[(S3 Bucket)]
    
    E[Application Load Balancer]
    F[Security Group]
    G[ECS Service<br>Auto Scaling Group]
    H[Fargate Task<br>Colyseus Container]
    
    I[(ElastiCache for Redis)]
    J[(DynamoDB)]
    
    K[CloudWatch<br>Logs, Metrics, Alarms]
    L[Secrets Manager]
    M[IAM Roles]
    
    
    %% (连接关系 A-->B 等保持不变)
    A -->|Request| B
    B --> C
    C --o|Static Assets| D
    C -->|Dynamic Traffic| E
    E -->|Forwards Traffic| F
    F -->|Allows Traffic| G
    G --> H
    H <-->|State Sync| I
    H -->|Data I/O| J
    H -->|logging| K
    H -->|On Start| L
    
        
    subgraph Supporting Services
        K
        L
        M
    end

    %% 使用完整的嵌套结构
    subgraph VPC - Virtual Private Cloud
        
        subgraph Public Subnets Multi-AZ
            E
            F
        end
        
        subgraph Private Subnets Multi-AZ
            G
            H
            I
            J
        end
        
    end
```

## 3. 技術スタック 

| カテゴリ | 技術 | 目的 |
|----------|------|------|
| クラウド | **AWS (Amazon Web Services)** | 主要なクラウドプラットフォーム |
| コンテナ | **Docker**, **Amazon ECR** | アプリケーションのパッケージ化とレジストリ |
| オーケストレーション | **Amazon ECS on AWS Fargate** | サーバーレスなコンテナ実行環境 |
| IaC | **Terraform** | インフラのコードによる宣言的な管理 |
| CI/CD | **GitHub Actions** | ビルド、テスト、デプロイの自動化 |
| ネットワーク | **VPC**, **ALB**, **CloudFront**, **WAF** | 高可用なトラフィック管理とセキュリティ |
| データストア | **ElastiCache (Redis)**, **DynamoDB** | 状態同期と永続的データストレージ |
| 監視 | **Amazon CloudWatch** | ログ、メトリクス、アラーム |
| セキュリティ | **IAM**, **Secrets Manager** | 権限管理と機密情報管理 |
| アプリケーション | **Colyseus (Node.js, TypeScript)** | リアルタイム通信サーバー |

---

## 4. プロジェクトロードマップ  

本プロジェクトは、以下の 4 つのフェーズで段階的に構築を進めています。

###  フェーズ1：ローカルでの実行と手動デプロイ
- [x] Colyseusアプリケーションのコンテナ化 (Docker)  
- [x] Dockerイメージのビルドと ECR へのプッシュ  
- [x] AWS コンソール上での手動デプロイ検証  

**目的:**  
アプリケーションの動作確認と、クラウド上でコンテナを動かすための基本的な要素を理解する。

---

###  フェーズ2：Terraform によるインフラのコード化 (IaC)
- [x] VPC、サブネット、ルートテーブル等のネットワーク基盤のコード化  
- [x] ECS クラスター、タスク定義、サービスのコード化  
- [x] `terraform apply` によるインフラの自動構築  

**目的:**  
手動操作を排除し、再現可能で一貫性のあるインフラをコードで管理する。

---

###  フェーズ3：データ層とネットワーク層の統合
- [x] ElastiCache (Redis) と DynamoDB の追加  
- [x] Application Load Balancer (ALB) の導入  
- [x] セキュリティグループによる精密なアクセスコントロール  

**目的:**  
状態管理と永続化データ層を統合し、安全な公開エンドポイントを持つ本格的なバックエンドを構築する。

---

###  フェーズ4：CI/CD パイプラインの構築と最終化
- [ ] GitHub Actions ワークフローの作成  
- [ ] OIDC による AWS 認証のセキュアな設定  
- [ ] `git push` をトリガーとした、ビルドからデプロイまでの完全自動化  

**目的:**  
開発から本番リリースまでのプロセスを自動化し、迅速なイテレーションを可能にする。

---

## 5. 現在の進捗 

**フェーズ1、2、3は完了済み**です。

- **コンテナ化、IaCによるインフラ構築**に加え、**データ層とネットワーク層の統合**が完了しました。
- **ElastiCache (Redis)** による状態管理、**DynamoDB** による永続化、そして **ALB** 経由での安全なトラフィックルーティングが実現されています。
- これにより、スケーラブルで高可用性なバックエンドシステムの基礎が完成しました。

**現在の作業:** フェーズ4（CI/CD パイプラインの構築）の準備を開始。
- 優先タスク例: GitHub Actions ワークフローの作成、OIDCによるAWS認証のセキュアな設定、`git push`をトリガーとしたビルドからデプロイまでの完全自動化。

**次のステップ（短期）:**
1. GitHub Actions ワークフローを作成し、OIDC を用いたセキュアな AWS 認証を設定する。
2. アプリケーションのビルド、テスト、Docker イメージのプッシュを自動化する。
3. `main` ブランチへのマージをトリガーに、Terraform の適用と ECS サービスの更新が自動的に行われるパイプラインを構築する。

---

</div>

<div id="english">

# 🎮 Colyseus on AWS: Production-Grade IaC / CI/CD Portfolio

## 1. Project Overview

This is a personal portfolio project aimed at running the real-time multiplayer game server **[Colyseus](https://www.colyseus.io/)** on the **AWS cloud with production-level quality**.

By fully adopting **Infrastructure as Code (Terraform)** and **CI/CD (GitHub Actions)** practices, this project demonstrates the process of building a **reproducible and automated cloud-native system** that is highly available, scalable, secure, and cost-effective.

---

## 2. Target Architecture

The following is the overall architecture diagram that this project aims to achieve.
It is designed with multi-layered defense and high availability through Multi-AZ, from user requests to data storage.

```mermaid
graph TD
    A((User / Game Client))
    B[🛡AWS WAF & Shield<br>DDoS & Attack Protection]
    C[CloudFront CDN]
    D[(S3 Bucket)]
    
    E[Application Load Balancer]
    F[Security Group]
    G[ECS Service<br>Auto Scaling Group]
    H[Fargate Task<br>Colyseus Container]
    
    I[(ElastiCache for Redis)]
    J[(DynamoDB)]
    
    K[CloudWatch<br>Logs, Metrics, Alarms]
    L[Secrets Manager]
    M[IAM Roles]
    
    
    A -->|Request| B
    B --> C
    C --o|Static Assets| D
    C -->|Dynamic Traffic| E
    E -->|Forwards Traffic| F
    F -->|Allows Traffic| G
    G --> H
    H <-->|State Sync| I
    H -->|Data I/O| J
    H -->|logging| K
    H -->|On Start| L
    
        
    subgraph Supporting Services
        K
        L
        M
    end

    subgraph VPC - Virtual Private Cloud
        
        subgraph Public Subnets Multi-AZ
            E
            F
        end
        
        subgraph Private Subnets Multi-AZ
            G
            H
            I
            J
        end
        
    end
```

## 3. Technology Stack

| Category | Technology | Purpose |
|----------|------|------|
| Cloud | **AWS (Amazon Web Services)** | Main cloud platform |
| Container | **Docker**, **Amazon ECR** | Application packaging and registry |
| Orchestration | **Amazon ECS on AWS Fargate** | Serverless container execution environment |
| IaC | **Terraform** | Declarative management of infrastructure as code |
| CI/CD | **GitHub Actions** | Automation of build, test, and deploy |
| Network | **VPC**, **ALB**, **CloudFront**, **WAF** | Highly available traffic management and security |
| Datastore | **ElastiCache (Redis)**, **DynamoDB** | State synchronization and persistent data storage |
| Monitoring | **Amazon CloudWatch** | Logs, metrics, and alarms |
| Security | **IAM**, **Secrets Manager** | Permissions and secrets management |
| Application | **Colyseus (Node.js, TypeScript)** | Real-time communication server |

---

## 4. Project Roadmap

This project is being built in the following four phases.

### Phase 1: Local Execution and Manual Deployment
- [x] Containerize the Colyseus application (Docker)
- [x] Build Docker image and push to ECR
- [x] Manual deployment verification on the AWS console

**Objective:**
To confirm the application's operation and understand the basic elements for running containers in the cloud.

---

### Phase 2: Infrastructure as Code with Terraform (IaC)
- [x] Code the network infrastructure such as VPC, subnets, and route tables
- [x] Code the ECS cluster, task definitions, and services
- [x] Automate infrastructure creation with `terraform apply`

**Objective:**
To eliminate manual operations and manage a reproducible and consistent infrastructure with code.

---

### Phase 3: Integration of Data and Network Layers
- [x] Add ElastiCache (Redis) and DynamoDB
- [x] Introduce Application Load Balancer (ALB)
- [x] Precise access control with security groups

**Objective:**
To integrate the state management and persistent data layers, and build a full-fledged backend with a secure public endpoint.

---

### Phase 4: Building the CI/CD Pipeline and Finalization
- [ ] Create GitHub Actions workflow
- [ ] Securely configure AWS authentication with OIDC
- [ ] Fully automate the process from build to deployment triggered by `git push`

**Objective:**
To automate the process from development to production release, enabling rapid iteration.

---

## 5. Current Progress

**Phases 1, 2, and 3 are complete.**

- In addition to **containerization and IaC-based infrastructure provisioning**, the **data and network layers have been integrated**.
- State management via **ElastiCache (Redis)**, persistence with **DynamoDB**, and secure traffic routing through an **ALB** are now implemented.
- This establishes the foundation for a scalable and highly available backend system.

**Current Work:** Preparing to start Phase 4 (Building the CI/CD Pipeline).
- Priority tasks include: Creating a GitHub Actions workflow, securely configuring AWS authentication with OIDC, and fully automating the build-to-deployment process triggered by `git push`.

**Next Steps (Short-term):**
1. Create a GitHub Actions workflow and configure secure AWS authentication using OIDC.
2. Automate application building, testing, and pushing the Docker image.
3. Build a pipeline that automatically applies Terraform changes and updates the ECS service, triggered by a merge to the `main` branch.

---

</div>