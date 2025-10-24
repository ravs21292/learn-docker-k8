# Terraform + Kubernetes + CI/CD Flow Guide

This guide explains how Terraform, Kubernetes, and CI/CD work together in your project to create a complete automated deployment pipeline.

## 🏗️ The Complete Flow

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              DEVELOPMENT WORKFLOW                              │
└─────────────────────────────────────────────────────────────────────────────────┘

1. DEVELOPER WORKFLOW
   ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
   │   Code      │───▶│   Commit    │───▶│   Push      │───▶│  GitHub     │
   │  Changes    │    │   Changes   │    │   to Git    │    │ Repository  │
   └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
                                                                    │
                                                                    ▼
2. CI/CD PIPELINE (GitHub Actions)
   ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
   │   Trigger   │───▶│   Test      │───▶│   Build     │───▶│   Deploy    │
   │   (Push)    │    │   Code      │    │   Docker    │    │   to K8s    │
   └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
                                                                    │
                                                                    ▼
3. INFRASTRUCTURE (Terraform)
   ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
   │   AWS       │───▶│   EKS       │───▶│   ECR       │───▶│   RDS       │
   │   Resources │    │   Cluster   │    │   Registry  │    │   Database  │
   └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
                                                                    │
                                                                    ▼
4. APPLICATION (Kubernetes)
   ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
   │   Pods      │───▶│  Services   │───▶│  Ingress    │───▶│  Monitoring │
   │  (App)      │    │ (Load Bal.) │    │ (External)  │    │ (Prometheus)│
   └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
```

## 🔧 How Each Component Works

### 1. **Terraform** - Infrastructure as Code
**Purpose**: Creates and manages your AWS infrastructure

**What it creates**:
- **EKS Cluster**: Kubernetes cluster on AWS
- **VPC & Networking**: Private/public subnets, security groups
- **RDS Database**: Managed PostgreSQL database
- **ECR Repository**: Container registry for your Docker images
- **IAM Roles**: Permissions for EKS and applications

**Files**:
- `terraform/main.tf` - Main infrastructure configuration
- `terraform/variables.tf` - Configurable parameters
- `terraform/outputs.tf` - Output values after deployment

### 2. **Kubernetes (K8s)** - Container Orchestration
**Purpose**: Manages your application containers

**What it manages**:
- **Pods**: Your application containers
- **Services**: Load balancing and service discovery
- **Ingress**: External access to your application
- **ConfigMaps**: Configuration management
- **Secrets**: Sensitive data (passwords, API keys)
- **Deployments**: Rolling updates and scaling

**Files**:
- `k8s/app/deployment.yaml` - Application deployment
- `k8s/app/service.yaml` - Service configuration
- `k8s/ingress.yaml` - External access
- `k8s/secret.yaml` - Sensitive data
- `k8s/configmap.yaml` - Configuration

### 3. **CI/CD Pipeline** - Automation
**Purpose**: Automates testing, building, and deployment

**What it does**:
- **Tests**: Runs unit tests and linting
- **Builds**: Creates Docker images
- **Pushes**: Uploads images to ECR
- **Deploys**: Updates Kubernetes deployments
- **Monitors**: Checks deployment health

**Files**:
- `.github/workflows/deploy.yml` - GitHub Actions workflow

## 🚀 Step-by-Step Flow

### Phase 1: Infrastructure Setup (One-time)

```bash
# 1. Configure AWS credentials
aws configure

# 2. Deploy infrastructure with Terraform
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

terraform init
terraform plan
terraform apply
```

**What happens**:
- Terraform creates EKS cluster, VPC, RDS, ECR
- You get cluster endpoint and credentials
- Infrastructure is ready for applications

### Phase 2: Application Deployment

```bash
# 1. Configure kubectl for your EKS cluster
aws eks update-kubeconfig --region us-west-2 --name python-k8s-app-eks

# 2. Deploy application to Kubernetes
kubectl apply -f k8s/

# 3. Check deployment
kubectl get pods -n python-k8s-app
```

**What happens**:
- Kubernetes creates pods, services, ingress
- Application connects to RDS database
- External access is configured

### Phase 3: CI/CD Automation

```bash
# 1. Push code to GitHub
git add .
git commit -m "Add new feature"
git push origin main
```

**What happens automatically**:
1. **GitHub Actions triggers**
2. **Tests run** (unit tests, linting)
3. **Docker image builds** and pushes to ECR
4. **Kubernetes deployment updates** with new image
5. **Health checks verify** deployment success

## 🔄 The Complete Cycle

### Development → Production Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    COMPLETE DEVELOPMENT CYCLE                   │
└─────────────────────────────────────────────────────────────────┘

1. LOCAL DEVELOPMENT
   ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
   │   Code      │───▶│  Test       │───▶│  Docker     │
   │  Changes    │    │  Locally    │    │  Compose    │
   └─────────────┘    └─────────────┘    └─────────────┘
                                │
                                ▼
2. GIT WORKFLOW
   ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
   │  Feature    │───▶│  Pull       │───▶│   Merge     │
   │  Branch     │    │  Request    │    │   to Main   │
   └─────────────┘    └─────────────┘    └─────────────┘
                                │
                                ▼
3. CI/CD PIPELINE
   ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
   │  GitHub     │───▶│  Build &    │───▶│  Deploy to  │
   │  Actions    │    │  Test       │    │  Kubernetes │
   └─────────────┘    └─────────────┘    └─────────────┘
                                │
                                ▼
4. PRODUCTION
   ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
   │  Kubernetes │───▶│  Monitoring │───▶│  Users      │
   │  Cluster    │    │  & Alerts   │    │  Access     │
   └─────────────┘    └─────────────┘    └─────────────┘
```

## 🛠️ How to Use Everything Together

### 1. **Initial Setup** (One-time)

```bash
# Step 1: Clone and configure
git clone https://github.com/YOUR_USERNAME/learn-docker-k8.git
cd learn-docker-k8
cp env.template .env
# Edit .env with your AWS credentials

# Step 2: Deploy infrastructure
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars
terraform init
terraform apply

# Step 3: Configure kubectl
aws eks update-kubeconfig --region us-west-2 --name python-k8s-app-eks

# Step 4: Deploy application
kubectl apply -f k8s/

# Step 5: Set up GitHub secrets
# Go to GitHub → Settings → Secrets → Actions
# Add: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY
```

### 2. **Daily Development Workflow**

```bash
# Step 1: Make changes locally
# Edit your code in app/

# Step 2: Test locally
cd docker
docker-compose up -d
curl http://localhost:8000/api/v1/health

# Step 3: Commit and push
git add .
git commit -m "Add new feature"
git push origin main

# Step 4: Watch CI/CD pipeline
# Go to GitHub → Actions tab
# Watch the pipeline run automatically

# Step 5: Verify deployment
kubectl get pods -n python-k8s-app
curl https://your-domain.com/api/v1/health
```

### 3. **Monitoring and Maintenance**

```bash
# Check application status
kubectl get pods -n python-k8s-app
kubectl logs -f deployment/python-k8s-app-deployment -n python-k8s-app

# Access monitoring
kubectl port-forward svc/prometheus-service 9090:9090 -n monitoring
kubectl port-forward svc/grafana-service 3000:3000 -n monitoring

# Scale application
kubectl scale deployment python-k8s-app-deployment --replicas=5 -n python-k8s-app

# Rollback if needed
./scripts/rollback.sh
```

## 📊 Key Benefits of This Setup

### 1. **Infrastructure as Code (Terraform)**
- **Reproducible**: Same infrastructure every time
- **Version Controlled**: Track infrastructure changes
- **Cost Effective**: Only pay for what you use
- **Scalable**: Easy to modify and scale

### 2. **Container Orchestration (Kubernetes)**
- **High Availability**: Automatic pod restarts
- **Scaling**: Automatic scaling based on load
- **Zero Downtime**: Rolling updates
- **Resource Management**: CPU and memory limits

### 3. **Automated CI/CD**
- **Fast Deployments**: Automated testing and deployment
- **Quality Assurance**: Automated testing and linting
- **Rollback**: Automatic rollback on failure
- **Monitoring**: Built-in health checks

## 🎯 Real-World Example

Let's say you want to add a new API endpoint:

### 1. **Local Development**
```bash
# Edit app/routes/users.py
# Add new endpoint
# Test locally with docker-compose
```

### 2. **Git Workflow**
```bash
git checkout -b feature/new-endpoint
git add .
git commit -m "Add new user endpoint"
git push origin feature/new-endpoint
# Create pull request
```

### 3. **CI/CD Pipeline**
- GitHub Actions runs tests
- If tests pass, merge to main
- Pipeline builds new Docker image
- Pushes image to ECR
- Updates Kubernetes deployment
- Verifies deployment health

### 4. **Production**
- New endpoint is live
- Monitoring shows healthy status
- Users can access new endpoint

## 🚨 Troubleshooting Common Issues

### 1. **Terraform Issues**
```bash
# Check Terraform state
terraform show
terraform plan

# Fix state issues
terraform refresh
terraform apply
```

### 2. **Kubernetes Issues**
```bash
# Check pod status
kubectl describe pod <pod-name> -n python-k8s-app

# Check logs
kubectl logs <pod-name> -n python-k8s-app

# Check events
kubectl get events -n python-k8s-app
```

### 3. **CI/CD Issues**
- Check GitHub Actions logs
- Verify AWS credentials
- Check ECR permissions
- Verify Kubernetes connectivity

## 📚 Next Steps

1. **Customize Configuration**: Modify `terraform.tfvars` for your needs
2. **Add Monitoring**: Set up custom Grafana dashboards
3. **Implement Security**: Add network policies and RBAC
4. **Scale Up**: Add more environments (dev, staging, prod)
5. **Add Features**: Implement blue-green deployments

---

This setup gives you a production-ready, scalable, and maintainable application deployment pipeline! 🚀
