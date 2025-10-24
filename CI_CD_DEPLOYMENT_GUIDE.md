# Complete CI/CD and Automated Deployment Guide

This comprehensive guide will walk you through setting up a complete CI/CD pipeline and automated deployment process for your Docker/Kubernetes project.

## 🚀 Overview

Your project already has:
- ✅ Docker containerization
- ✅ Kubernetes manifests
- ✅ GitHub Actions CI/CD pipeline
- ✅ Terraform infrastructure
- ✅ Monitoring setup

## 📋 Prerequisites

Before starting, ensure you have:

1. **AWS Account** with appropriate permissions
2. **GitHub Repository** (fork this project)
3. **Local Tools**:
   - Docker Desktop
   - kubectl
   - AWS CLI
   - Terraform
   - Git

## 🏗️ Step-by-Step Deployment Process

### Step 1: Fork and Clone Repository

```bash
# Fork this repository on GitHub, then clone your fork
git clone https://github.com/YOUR_USERNAME/learn-docker-k8.git
cd learn-docker-k8
```

### Step 2: Set Up AWS Infrastructure

#### 2.1 Configure AWS CLI

```bash
# Install AWS CLI (if not already installed)
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Configure AWS credentials
aws configure
# Enter your AWS Access Key ID, Secret Access Key, and region (e.g., us-west-2)
```

#### 2.2 Deploy Infrastructure with Terraform

```bash
# Navigate to terraform directory
cd terraform

# Copy and edit terraform variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your specific values

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Deploy infrastructure
terraform apply
# Type 'yes' when prompted
```

This will create:
- EKS cluster
- ECR repository
- RDS PostgreSQL database
- VPC and networking
- Security groups
- IAM roles

### Step 3: Configure GitHub Secrets

In your GitHub repository, go to **Settings > Secrets and variables > Actions** and add:

```
AWS_ACCESS_KEY_ID: your-aws-access-key
AWS_SECRET_ACCESS_KEY: your-aws-secret-key
DOCKER_USERNAME: your-dockerhub-username (optional)
DOCKER_PASSWORD: your-dockerhub-password (optional)
```

### Step 4: Set Up Container Registry

#### 4.1 Create ECR Repository (if not created by Terraform)

```bash
# Create ECR repository
aws ecr create-repository --repository-name python-k8s-app --region us-west-2

# Get login token
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin YOUR_ACCOUNT_ID.dkr.ecr.us-west-2.amazonaws.com
```

#### 4.2 Update Kubernetes Manifests

The deployment.yaml already references the ECR repository. Update the image name if needed:

```yaml
# In k8s/app/deployment.yaml
image: YOUR_ACCOUNT_ID.dkr.ecr.us-west-2.amazonaws.com/python-k8s-app:latest
```

### Step 5: Deploy to Kubernetes

#### 5.1 Configure kubectl

```bash
# Update kubeconfig for your EKS cluster
aws eks update-kubeconfig --region us-west-2 --name python-k8s-app-eks

# Verify connection
kubectl get nodes
```

#### 5.2 Deploy Application

```bash
# Apply all Kubernetes manifests
kubectl apply -f k8s/

# Verify deployment
kubectl get pods -n python-k8s-app
kubectl get services -n python-k8s-app
kubectl get ingress -n python-k8s-app
```

### Step 6: Set Up CI/CD Pipeline

Your GitHub Actions workflow is already configured! Here's what happens:

#### 6.1 Automatic Triggers

- **Push to main**: Triggers full CI/CD pipeline
- **Pull Request**: Runs tests only
- **Push to develop**: Triggers CI/CD pipeline

#### 6.2 Pipeline Stages

1. **Test Stage**:
   - Code checkout
   - Python environment setup
   - Dependency installation
   - Unit tests execution
   - Code linting

2. **Build Stage** (main branch only):
   - Docker image build
   - Push to ECR
   - Image tagging with commit SHA

3. **Deploy Stage** (main branch only):
   - Update Kubernetes deployment
   - Rolling update with zero downtime
   - Health checks and verification

4. **Rollback Stage** (on failure):
   - Automatic rollback to previous version
   - Status verification

### Step 7: Monitor and Verify

#### 7.1 Check Application Health

```bash
# Get application URL
kubectl get ingress -n python-k8s-app

# Test health endpoint
curl https://your-domain.com/api/v1/health
```

#### 7.2 Monitor Logs

```bash
# View application logs
kubectl logs -f deployment/python-k8s-app-deployment -n python-k8s-app

# View all pods
kubectl get pods -n python-k8s-app
```

#### 7.3 Access Monitoring

- **Prometheus**: `kubectl port-forward svc/prometheus-service 9090:9090 -n monitoring`
- **Grafana**: `kubectl port-forward svc/grafana-service 3000:3000 -n monitoring`

## 🔄 Development Workflow

### Local Development

```bash
# Start local development environment
cd docker
docker-compose up -d

# Test locally
curl http://localhost:8000/api/v1/health

# Stop when done
docker-compose down
```

### Making Changes

1. **Create Feature Branch**:
   ```bash
   git checkout -b feature/new-feature
   ```

2. **Make Changes and Test Locally**:
   ```bash
   # Test with Docker Compose
   docker-compose up -d
   # Make your changes
   # Test your changes
   ```

3. **Commit and Push**:
   ```bash
   git add .
   git commit -m "Add new feature"
   git push origin feature/new-feature
   ```

4. **Create Pull Request**:
   - Go to GitHub
   - Create pull request to main branch
   - CI will run tests automatically

5. **Merge to Main**:
   - After PR approval and tests pass
   - Merge to main branch
   - CI/CD will automatically deploy to production

## 🚨 Troubleshooting

### Common Issues

#### 1. Pod Not Starting

```bash
# Check pod status
kubectl describe pod <pod-name> -n python-k8s-app

# Check logs
kubectl logs <pod-name> -n python-k8s-app
```

#### 2. Database Connection Issues

```bash
# Check database pod
kubectl get pods -n python-k8s-app

# Test database connection
kubectl exec -it <postgres-pod> -n python-k8s-app -- psql -U user -d mydb
```

#### 3. Image Pull Issues

```bash
# Check if image exists in ECR
aws ecr describe-images --repository-name python-k8s-app --region us-west-2

# Check ECR permissions
aws ecr get-login-password --region us-west-2
```

#### 4. Rollback Deployment

```bash
# Manual rollback
kubectl rollout undo deployment/python-k8s-app-deployment -n python-k8s-app

# Check rollback status
kubectl rollout status deployment/python-k8s-app-deployment -n python-k8s-app
```

## 📊 Monitoring and Observability

### Health Checks

Your application includes comprehensive health checks:

- **Liveness Probe**: `/api/v1/health/live`
- **Readiness Probe**: `/api/v1/health/ready`
- **Startup Probe**: `/api/v1/health`

### Metrics and Logging

- **Prometheus**: Metrics collection
- **Grafana**: Visualization dashboards
- **AWS CloudWatch**: Log aggregation
- **Kubernetes Events**: Cluster events

### Scaling

#### Horizontal Scaling

```bash
# Scale application pods
kubectl scale deployment python-k8s-app-deployment --replicas=5 -n python-k8s-app

# Check HPA status
kubectl get hpa -n python-k8s-app
```

#### Vertical Scaling

Update resource limits in `k8s/app/deployment.yaml`:

```yaml
resources:
  requests:
    memory: "512Mi"
    cpu: "500m"
  limits:
    memory: "1Gi"
    cpu: "1000m"
```

## 🔒 Security Best Practices

### 1. Secrets Management

```bash
# Create secrets
kubectl create secret generic python-k8s-app-secret \
  --from-literal=DATABASE_USER=user \
  --from-literal=DATABASE_PASSWORD=password \
  --from-literal=SECRET_KEY=your-secret-key \
  --from-literal=JWT_SECRET=your-jwt-secret \
  -n python-k8s-app
```

### 2. Network Policies

Network policies are configured to restrict pod-to-pod communication.

### 3. RBAC

Role-based access control is configured for secure access.

### 4. Image Security

- ECR vulnerability scanning enabled
- Non-root user in containers
- Minimal base images

## 💰 Cost Optimization

### 1. Use Spot Instances

Configure node groups to use spot instances for non-critical workloads.

### 2. Right-size Resources

Monitor actual usage and adjust resource requests/limits.

### 3. Cluster Autoscaler

Enable cluster autoscaler for dynamic scaling.

### 4. Reserved Instances

Use reserved instances for predictable workloads.

## 🎯 Next Steps

1. **Set up monitoring alerts** for critical metrics
2. **Configure backup strategies** for database and configurations
3. **Implement blue-green deployments** for zero-downtime updates
4. **Set up multi-environment** (dev, staging, prod) deployments
5. **Implement security scanning** in CI/CD pipeline
6. **Add performance testing** to CI/CD pipeline

## 📚 Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest)

## 🆘 Support

If you encounter issues:

1. Check the troubleshooting section above
2. Review Kubernetes events: `kubectl get events -n python-k8s-app`
3. Check application logs: `kubectl logs -f deployment/python-k8s-app-deployment -n python-k8s-app`
4. Verify AWS resources in the AWS Console
5. Check GitHub Actions logs for CI/CD issues

---

**Congratulations!** You now have a complete, production-ready CI/CD pipeline with automated deployments to Kubernetes! 🎉
