# Practical Step-by-Step Guide

This guide shows you exactly how to use Terraform, Kubernetes, and CI/CD together in your project.

## 🎯 What You'll Learn

- How Terraform creates your AWS infrastructure
- How Kubernetes manages your application
- How CI/CD automates your deployments
- How everything works together

## 📋 Prerequisites Checklist

Before starting, make sure you have:

- [ ] AWS Account with admin access
- [ ] GitHub account
- [ ] Docker Desktop installed
- [ ] Git installed
- [ ] AWS CLI installed (`aws configure`)
- [ ] kubectl installed
- [ ] Terraform installed

## 🚀 Phase 1: Infrastructure Setup (Terraform)

### Step 1: Configure Terraform

```bash
# Navigate to terraform directory
cd terraform

# Copy the example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values
nano terraform.tfvars
```

**Example terraform.tfvars:**
```hcl
aws_region = "us-west-2"
project_name = "python-k8s-app"
environment = "production"
db_password = "your-secure-password-here"
node_instance_types = ["t3.medium"]
node_min_size = 1
node_max_size = 5
node_desired_size = 2
```

### Step 2: Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Review what will be created
terraform plan

# Deploy infrastructure (takes 10-15 minutes)
terraform apply
# Type 'yes' when prompted
```

**What Terraform creates:**
- ✅ EKS Kubernetes cluster
- ✅ VPC with public/private subnets
- ✅ RDS PostgreSQL database
- ✅ ECR container registry
- ✅ Security groups and IAM roles

### Step 3: Get Cluster Information

```bash
# Get cluster name
terraform output cluster_name

# Get ECR repository URL
terraform output ecr_repository_url

# Get database endpoint
terraform output db_endpoint
```

## 🐳 Phase 2: Application Setup (Kubernetes)

### Step 1: Configure kubectl

```bash
# Configure kubectl to connect to your EKS cluster
aws eks update-kubeconfig --region us-west-2 --name python-k8s-app-eks

# Verify connection
kubectl get nodes
```

### Step 2: Create Secrets

```bash
# Create Kubernetes secrets for your application
kubectl create secret generic python-k8s-app-secret \
  --from-literal=DATABASE_USER=postgres \
  --from-literal=DATABASE_PASSWORD=your-secure-password \
  --from-literal=SECRET_KEY=your-secret-key-here \
  --from-literal=JWT_SECRET=your-jwt-secret-here \
  -n python-k8s-app
```

### Step 3: Deploy Application

```bash
# Deploy all Kubernetes resources
kubectl apply -f k8s/

# Check deployment status
kubectl get pods -n python-k8s-app
kubectl get services -n python-k8s-app
```

### Step 4: Verify Application

```bash
# Get application URL
kubectl get ingress -n python-k8s-app

# Test health endpoint
curl https://your-domain.com/api/v1/health
```

## 🔄 Phase 3: CI/CD Setup (GitHub Actions)

### Step 1: Configure GitHub Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions

Add these secrets:
- `AWS_ACCESS_KEY_ID`: Your AWS access key
- `AWS_SECRET_ACCESS_KEY`: Your AWS secret key

### Step 2: Test CI/CD Pipeline

```bash
# Make a small change to your code
echo "# Test change" >> README.md

# Commit and push
git add .
git commit -m "Test CI/CD pipeline"
git push origin main
```

### Step 3: Watch Pipeline Run

1. Go to GitHub → Actions tab
2. Watch the pipeline run:
   - ✅ Tests run
   - ✅ Docker image builds
   - ✅ Image pushes to ECR
   - ✅ Kubernetes deployment updates
   - ✅ Health checks verify deployment

## 🔧 Phase 4: Daily Development Workflow

### Making Changes

```bash
# 1. Create feature branch
git checkout -b feature/new-feature

# 2. Make your changes
# Edit files in app/

# 3. Test locally
cd docker
docker-compose up -d
curl http://localhost:8000/api/v1/health

# 4. Commit changes
git add .
git commit -m "Add new feature"

# 5. Push to GitHub
git push origin feature/new-feature

# 6. Create pull request
# Go to GitHub and create PR

# 7. Merge to main (triggers CI/CD)
# After PR approval, merge to main
```

### What Happens Automatically

1. **GitHub Actions triggers** when you push to main
2. **Tests run** (unit tests, linting)
3. **Docker image builds** with your changes
4. **Image pushes to ECR** with commit SHA tag
5. **Kubernetes deployment updates** with new image
6. **Rolling update** deploys with zero downtime
7. **Health checks verify** deployment success

## 📊 Phase 5: Monitoring and Maintenance

### Check Application Status

```bash
# Check pod status
kubectl get pods -n python-k8s-app

# Check logs
kubectl logs -f deployment/python-k8s-app-deployment -n python-k8s-app

# Check events
kubectl get events -n python-k8s-app
```

### Access Monitoring

```bash
# Prometheus (metrics)
kubectl port-forward svc/prometheus-service 9090:9090 -n monitoring
# Open http://localhost:9090

# Grafana (dashboards)
kubectl port-forward svc/grafana-service 3000:3000 -n monitoring
# Open http://localhost:3000 (admin/admin123)
```

### Scale Application

```bash
# Scale up
kubectl scale deployment python-k8s-app-deployment --replicas=5 -n python-k8s-app

# Check scaling
kubectl get pods -n python-k8s-app
```

### Rollback if Needed

```bash
# Rollback to previous version
./scripts/rollback.sh

# Rollback to specific revision
./scripts/rollback.sh --revision 3
```

## 🎯 Real-World Example: Adding a New API Endpoint

Let's say you want to add a new `/api/v1/users` endpoint:

### 1. **Local Development**

```bash
# Create feature branch
git checkout -b feature/user-endpoint

# Edit app/routes/users.py
# Add new endpoint:
# @router.get("/users")
# async def get_users():
#     return {"users": []}

# Test locally
cd docker
docker-compose up -d
curl http://localhost:8000/api/v1/users
```

### 2. **Git Workflow**

```bash
# Commit changes
git add .
git commit -m "Add users endpoint"
git push origin feature/user-endpoint

# Create pull request on GitHub
# Review and merge to main
```

### 3. **Automatic Deployment**

- GitHub Actions runs tests
- If tests pass, merge to main
- Pipeline builds new Docker image
- Pushes image to ECR
- Updates Kubernetes deployment
- New endpoint is live in production!

### 4. **Verify in Production**

```bash
# Check deployment
kubectl get pods -n python-k8s-app

# Test new endpoint
curl https://your-domain.com/api/v1/users
```

## 🚨 Troubleshooting

### Common Issues and Solutions

#### 1. **Terraform Issues**

```bash
# If Terraform fails
terraform plan
terraform apply

# If state is corrupted
terraform refresh
terraform apply
```

#### 2. **Kubernetes Issues**

```bash
# Pod not starting
kubectl describe pod <pod-name> -n python-k8s-app
kubectl logs <pod-name> -n python-k8s-app

# Service not accessible
kubectl get services -n python-k8s-app
kubectl get ingress -n python-k8s-app
```

#### 3. **CI/CD Issues**

- Check GitHub Actions logs
- Verify AWS credentials
- Check ECR permissions
- Verify Kubernetes connectivity

#### 4. **Database Issues**

```bash
# Check database pod
kubectl get pods -n python-k8s-app

# Test database connection
kubectl exec -it <postgres-pod> -n python-k8s-app -- psql -U postgres -d mydb
```

## 📚 Understanding the Flow

### How Everything Connects

```
┌─────────────────────────────────────────────────────────────────┐
│                    YOUR COMPLETE SETUP                         │
└─────────────────────────────────────────────────────────────────┘

1. TERRAFORM (Infrastructure)
   ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
   │   AWS       │───▶│   EKS       │───▶│   ECR       │
   │   Account   │    │   Cluster   │    │   Registry  │
   └─────────────┘    └─────────────┘    └─────────────┘
                                │
                                ▼
2. KUBERNETES (Application)
   ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
   │   Pods      │───▶│  Services   │───▶│  Ingress    │
   │  (Your App) │    │ (Load Bal.) │    │ (External)  │
   └─────────────┘    └─────────────┘    └─────────────┘
                                │
                                ▼
3. CI/CD (Automation)
   ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
   │   GitHub    │───▶│   Build     │───▶│   Deploy    │
   │   Actions   │    │   & Test    │    │   to K8s    │
   └─────────────┘    └─────────────┘    └─────────────┘
```

### Key Benefits

- **Terraform**: Manages infrastructure as code
- **Kubernetes**: Orchestrates your containers
- **CI/CD**: Automates deployments
- **Together**: Complete automated pipeline

## 🎉 You're All Set!

You now have:

- ✅ **Infrastructure**: EKS cluster, RDS database, ECR registry
- ✅ **Application**: Kubernetes-managed Python app
- ✅ **CI/CD**: Automated testing and deployment
- ✅ **Monitoring**: Prometheus and Grafana
- ✅ **Security**: Network policies and RBAC
- ✅ **Scaling**: Horizontal pod autoscaling

## 🚀 Next Steps

1. **Customize**: Modify configurations for your needs
2. **Monitor**: Set up alerts and dashboards
3. **Scale**: Add more environments
4. **Secure**: Implement additional security measures
5. **Optimize**: Fine-tune performance and costs

---

**Congratulations!** You now understand how to use Terraform, Kubernetes, and CI/CD together to create a complete automated deployment pipeline! 🎉
