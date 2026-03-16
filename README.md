# Python + PostgreSQL + Kubernetes Project
This project is part of my backend engineering portfolio. The backend architecture, API design, and implementation were designed and built by me while exploring and learning core backend development concepts of Docker/Kubernates with AWS, which enhance my learning skills with devops.

A production-ready Python application with PostgreSQL database, containerized with Docker and deployed on Kubernetes with CI/CD pipeline.

## 🏗️ Project Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   GitHub        │    │   AWS EKS       │    │   AWS RDS       │
│   (CI/CD)       │───▶│   (Kubernetes)  │───▶│   (PostgreSQL)  │
│   Actions       │    │   Cluster       │    │   Database      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   ECR           │    │   ALB           │    │   CloudWatch    │
│   (Docker       │    │   (Load         │    │   (Logs &       │
│   Images)       │    │   Balancer)     │    │   Metrics)      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🔧 How Components Work Together

### Architecture Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              DEPLOYMENT FLOW                                    │
└─────────────────────────────────────────────────────────────────────────────────┘

┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Developer │───▶│   GitHub    │───▶│   GitHub    │───▶│   AWS ECR   │
│   (Code)    │    │   (Code)    │    │   Actions   │    │   (Images)  │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
                                                              │
                                                              ▼
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Terraform │───▶│   AWS EKS   │───▶│   K8s Pods  │◀───│   ECR Push  │
│ (Infra)     │    │ (Cluster)   │    │ (App/DB)    │    │ (Deploy)    │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
       │                   │                   │
       ▼                   ▼                   ▼
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   AWS VPC   │    │   AWS RDS   │    │   ALB/Ingress│
│ (Networking)│    │ (Database)  │    │ (Load Balancer)│
└─────────────┘    └─────────────┘    └─────────────┘
                                                              │
                                                              ▼
                                                   ┌─────────────┐
                                                   │   Users     │
                                                   │ (External)  │
                                                   └─────────────┘
```

### 1. **Docker Layer** (Containerization)
- **Purpose**: Packages the Python application and its dependencies into portable containers
- **Dockerfile**: Multi-stage build that creates optimized production images
- **docker-compose.yml**: Local development environment with PostgreSQL and Redis
- **Benefits**: Consistent environments, easy deployment, resource isolation

### 2. **Kubernetes Layer** (Orchestration)
- **Purpose**: Manages containerized applications at scale with high availability
- **Deployments**: Manages application pods with rolling updates
- **Services**: Provides stable network endpoints for pods
- **Ingress**: Routes external traffic to services with load balancing
- **ConfigMaps/Secrets**: Manages configuration and sensitive data
- **HPA**: Auto-scales pods based on CPU/memory usage
- **PDB**: Ensures minimum availability during updates

### 3. **Terraform Layer** (Infrastructure as Code)
- **Purpose**: Provisions and manages AWS infrastructure declaratively
- **EKS Cluster**: Creates managed Kubernetes cluster
- **VPC**: Sets up networking with public/private subnets
- **RDS**: Provisions managed PostgreSQL database
- **ECR**: Creates container registry for Docker images
- **IAM**: Manages permissions and roles
- **Benefits**: Reproducible infrastructure, version control, cost management

### 4. **Application Layer** (Python FastAPI)
- **Purpose**: RESTful API with database integration
- **FastAPI**: Modern, fast web framework with automatic API documentation
- **SQLAlchemy**: ORM for database operations
- **Pydantic**: Data validation and serialization
- **Health Checks**: Monitoring endpoints for Kubernetes probes

### 5. **Data Flow Explanation**

1. **Development**: Developer writes code and pushes to GitHub
2. **CI/CD**: GitHub Actions builds Docker image and pushes to ECR
3. **Infrastructure**: Terraform provisions AWS resources (EKS, RDS, VPC)
4. **Deployment**: Kubernetes pulls image from ECR and deploys pods
5. **Networking**: ALB routes traffic through Ingress to application pods
6. **Database**: Application connects to RDS PostgreSQL for data persistence
7. **Monitoring**: Prometheus collects metrics, Grafana visualizes data
8. **Scaling**: HPA automatically scales pods based on load

## 📁 Project Structure

```
learn-docker-k8/
├── app/                          # Python FastAPI application
│   ├── __init__.py
│   ├── main.py                   # FastAPI application entry point
│   ├── models/                   # SQLAlchemy database models
│   │   ├── __init__.py
│   │   ├── database.py           # Database configuration
│   │   └── user.py               # User model
│   ├── routes/                   # API route handlers
│   │   ├── __init__.py
│   │   ├── health.py             # Health check endpoints
│   │   └── users.py              # User management endpoints
│   ├── services/                 # Business logic layer
│   │   ├── __init__.py
│   │   └── database_service.py   # Database operations
│   └── requirements.txt          # Python dependencies
├── k8s/                         # Kubernetes manifests
│   ├── namespace.yaml           # K8s namespace definition
│   ├── configmap.yaml           # Application configuration
│   ├── secret.yaml              # Sensitive data (secrets)
│   ├── postgres/                # Database deployment
│   │   ├── deployment.yaml      # PostgreSQL pod deployment
│   │   └── service.yaml         # PostgreSQL service
│   ├── app/                     # Application deployment
│   │   ├── deployment.yaml      # Python app pod deployment
│   │   └── service.yaml         # Python app service
│   ├── ingress.yaml             # Load balancer configuration
│   ├── hpa.yaml                 # Horizontal Pod Autoscaler
│   └── pdb.yaml                 # Pod Disruption Budget
├── docker/                      # Containerization
│   ├── Dockerfile               # Multi-stage Docker build
│   ├── docker-compose.yml       # Local development setup
│   ├── .dockerignore            # Docker ignore patterns
│   └── init.sql                 # Database initialization
├── terraform/                   # Infrastructure as Code
│   ├── main.tf                  # Main Terraform configuration
│   ├── variables.tf             # Input variables
│   ├── outputs.tf               # Output values
│   └── terraform.tfvars.example # Example variables file
├── .github/workflows/           # CI/CD Pipeline
│   └── deploy.yml               # GitHub Actions workflow
├── scripts/                     # Deployment automation
│   ├── deploy.sh                # Zero-downtime deployment script
│   ├── rollback.sh              # Rollback procedure script
│   └── setup-aws.sh             # AWS setup automation
├── monitoring/                  # Observability stack
│   ├── prometheus-config.yaml   # Prometheus configuration
│   └── grafana-dashboard.json   # Grafana dashboard definition
├── README.md                    # This file
├── DEPLOYMENT.md                # Detailed deployment guide
└── env.example                  # Environment variables example
```

## 📋 Detailed File Explanations

### 🐍 **Application Layer** (`app/`)

| File | Purpose | Key Features |
|------|---------|--------------|
| `main.py` | FastAPI application entry point | - CORS middleware<br>- Database initialization<br>- Route registration<br>- Lifespan management |
| `models/database.py` | Database configuration | - SQLAlchemy engine setup<br>- Session management<br>- Connection pooling |
| `models/user.py` | User data model | - SQLAlchemy ORM model<br>- Pydantic schemas<br>- Data validation |
| `routes/health.py` | Health check endpoints | - `/health` - Basic health check<br>- `/health/ready` - Readiness probe<br>- `/health/live` - Liveness probe |
| `routes/users.py` | User management API | - CRUD operations<br>- Input validation<br>- Error handling |
| `services/database_service.py` | Business logic layer | - Database operations<br>- Transaction management<br>- Error handling |
| `requirements.txt` | Python dependencies | - FastAPI, SQLAlchemy, Pydantic<br>- Production dependencies<br>- Version pinning |

### 🐳 **Docker Layer** (`docker/`)

| File | Purpose | Key Features |
|------|---------|--------------|
| `Dockerfile` | Multi-stage container build | - Python 3.11 slim base<br>- Non-root user security<br>- Health check integration<br>- Optimized layers |
| `docker-compose.yml` | Local development setup | - PostgreSQL database<br>- Redis caching<br>- Volume persistence<br>- Network isolation |
| `init.sql` | Database initialization | - Schema creation<br>- Initial data<br>- Indexes setup |

### ☸️ **Kubernetes Layer** (`k8s/`)

| File | Purpose | Key Features |
|------|---------|--------------|
| `namespace.yaml` | K8s namespace | - Resource isolation<br>- RBAC boundaries |
| `configmap.yaml` | Application config | - Non-sensitive settings<br>- Environment variables |
| `secret.yaml` | Sensitive data | - Database credentials<br>- JWT secrets<br>- Encrypted storage |
| `app/deployment.yaml` | App pod management | - Rolling updates<br>- Health probes<br>- Resource limits<br>- Init containers |
| `app/service.yaml` | App networking | - ClusterIP service<br>- Load balancing<br>- Service discovery |
| `postgres/deployment.yaml` | Database pods | - Stateful deployment<br>- Volume persistence<br>- Health checks |
| `postgres/service.yaml` | Database networking | - Internal service<br>- Port exposure |
| `ingress.yaml` | External access | - ALB integration<br>- SSL termination<br>- Path routing |
| `hpa.yaml` | Auto-scaling | - CPU/Memory based scaling<br>- Min/Max replicas |
| `pdb.yaml` | Availability protection | - Minimum pod guarantee<br>- Disruption limits |

### 🏗️ **Terraform Layer** (`terraform/`)

| File | Purpose | Key Features |
|------|---------|--------------|
| `main.tf` | Infrastructure definition | - EKS cluster<br>- VPC networking<br>- RDS database<br>- ECR repository |
| `variables.tf` | Input parameters | - Configurable values<br>- Type validation<br>- Default values |
| `outputs.tf` | Resource outputs | - Cluster endpoints<br>- Database URLs<br>- ECR repository URLs |
| `terraform.tfvars.example` | Configuration template | - Example values<br>- Documentation |

### 🚀 **Deployment & Scripts** (`scripts/`)

| File | Purpose | Key Features |
|------|---------|--------------|
| `deploy.sh` | Zero-downtime deployment | - Rolling updates<br>- Health checks<br>- Rollback capability |
| `rollback.sh` | Emergency rollback | - Previous version restore<br>- Safety checks |
| `setup-aws.sh` | AWS environment setup | - Prerequisites installation<br>- Configuration |

### 📊 **Monitoring** (`monitoring/`)

| File | Purpose | Key Features |
|------|---------|--------------|
| `prometheus-config.yaml` | Metrics collection | - Scrape targets<br>- Collection rules |
| `grafana-dashboard.json` | Visualization | - Pre-built dashboards<br>- Alerting rules |

## 🛠️ Tech Stack

- **Backend**: Python 3.11 + FastAPI
- **Database**: PostgreSQL 15
- **Containerization**: Docker + Multi-stage builds
- **Orchestration**: Kubernetes (EKS)
- **Cloud Provider**: AWS (EKS, RDS, ALB, ECR, CloudWatch)
- **CI/CD**: GitHub Actions
- **Infrastructure**: Terraform
- **Monitoring**: Prometheus + Grafana
- **Caching**: Redis (optional)
- **Load Balancing**: AWS Application Load Balancer

## 🚀 Complete Deployment Guide

### Prerequisites

1. **Docker** (v20.10+) - Container runtime
2. **kubectl** (v1.28+) - Kubernetes CLI
3. **AWS CLI** (v2.0+) - AWS command line interface
4. **Terraform** (v1.0+) - Infrastructure as Code
5. **Git** - Version control
6. **Python** (v3.11+) - For local development

### Step 1: Local Development Setup

```bash
# 1. Clone the repository
git clone <your-repo-url>
cd learn-docker-k8

# 2. Set up environment variables
cp env.example .env
# Edit .env with your local configuration

# 3. Start local development environment
cd docker
docker-compose up -d

# 4. Verify all services are running
docker-compose ps
# Expected output:
# python-k8s-postgres   Up   5432/tcp
# python-k8s-app        Up   0.0.0.0:8000->8000/tcp
# python-k8s-redis      Up   6379/tcp

# 5. Test the application endpoints
curl http://localhost:8000/api/v1/health
curl http://localhost:8000/api/v1/users
curl http://localhost:8000/docs  # FastAPI auto-generated docs

# 6. View application logs
docker-compose logs -f app
docker-compose logs -f postgres

# 7. Access database directly
docker-compose exec postgres psql -U user -d mydb
```

### Step 2: AWS Infrastructure Setup

```bash
# 1. Configure AWS CLI
aws configure
# Enter your AWS Access Key ID, Secret Access Key, Region, and Output format

# 2. Navigate to terraform directory
cd terraform

# 3. Copy and configure variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your specific values:
# - aws_region = "us-west-2"
# - project_name = "your-project-name"
# - db_password = "your-secure-password"

# 4. Initialize Terraform
terraform init
# This downloads required providers and modules

# 5. Plan the infrastructure deployment
terraform plan
# Review the planned changes carefully

# 6. Deploy infrastructure (takes 10-15 minutes)
terraform apply
# Type 'yes' when prompted

# 7. Save important outputs
terraform output > terraform-outputs.txt
```

**What Terraform Creates:**
- VPC with public/private subnets across 3 AZs
- EKS cluster with managed node groups
- RDS PostgreSQL database
- ECR repository for Docker images
- Security groups and IAM roles
- Application Load Balancer

### Step 3: Configure Kubernetes Access

```bash
# 1. Update kubeconfig for EKS cluster
aws eks update-kubeconfig --region us-west-2 --name python-k8s-app-eks

# 2. Verify cluster connection
kubectl get nodes
kubectl get namespaces

# 3. Check cluster info
kubectl cluster-info
kubectl get pods --all-namespaces
```

### Step 4: Deploy Application to Kubernetes

```bash
# 1. Create namespace
kubectl apply -f k8s/namespace.yaml

# 2. Apply secrets (update with your values first)
kubectl apply -f k8s/secret.yaml

# 3. Apply configuration
kubectl apply -f k8s/configmap.yaml

# 4. Deploy PostgreSQL
kubectl apply -f k8s/postgres/

# 5. Wait for database to be ready
kubectl wait --for=condition=ready pod -l app=postgres -n python-k8s-app --timeout=300s

# 6. Deploy application
kubectl apply -f k8s/app/

# 7. Apply production configurations
kubectl apply -f k8s/hpa.yaml
kubectl apply -f k8s/pdb.yaml

# 8. Verify deployment
kubectl get pods -n python-k8s-app
kubectl get services -n python-k8s-app
kubectl get ingress -n python-k8s-app

# 9. Check application logs
kubectl logs -f deployment/python-k8s-app-deployment -n python-k8s-app

# 10. Test application health
kubectl exec -it deployment/python-k8s-app-deployment -n python-k8s-app -- curl localhost:8000/api/v1/health
```

### Step 5: Set up CI/CD Pipeline

```bash
# 1. Fork this repository to your GitHub account

# 2. Configure GitHub Secrets
# Go to: Settings → Secrets and variables → Actions
# Add these secrets:
# - AWS_ACCESS_KEY_ID: Your AWS access key
# - AWS_SECRET_ACCESS_KEY: Your AWS secret key
# - ECR_REPOSITORY_URI: From terraform output
# - EKS_CLUSTER_NAME: python-k8s-app-eks
# - AWS_REGION: us-west-2

# 3. Create GitHub Actions workflow
mkdir -p .github/workflows
# Copy the deploy.yml workflow file

# 4. Push to main branch to trigger deployment
git add .
git commit -m "Initial deployment setup"
git push origin main

# 5. Monitor deployment in GitHub Actions tab
```

### Step 6: Production Configuration

```bash
# 1. Configure domain and SSL
# Update k8s/ingress.yaml with your domain
# Update certificate ARN in ingress annotations

# 2. Set up monitoring
kubectl apply -f monitoring/prometheus-config.yaml

# 3. Configure auto-scaling
kubectl get hpa -n python-k8s-app
kubectl describe hpa python-k8s-app-hpa -n python-k8s-app

# 4. Set up log aggregation
# Configure CloudWatch or ELK stack for centralized logging
```

### Step 7: Verify Production Deployment

```bash
# 1. Get application URL
kubectl get ingress -n python-k8s-app

# 2. Test all endpoints
curl https://your-domain.com/api/v1/health
curl https://your-domain.com/api/v1/users
curl https://your-domain.com/docs

# 3. Check metrics
kubectl top pods -n python-k8s-app
kubectl top nodes

# 4. Verify auto-scaling
# Generate load to test HPA
kubectl run -i --tty load-generator --rm --image=busybox --restart=Never -- /bin/sh
# Inside the pod: while true; do wget -q -O- http://python-k8s-app-service:80/api/v1/health; done
```

## 🔧 Development Commands

```bash
# Local development
docker-compose up -d              # Start all services
docker-compose down               # Stop all services
docker-compose logs -f app        # View app logs
docker-compose exec app bash      # Access app container

# Kubernetes operations
kubectl get pods -n python-k8s-app
kubectl describe pod <pod-name> -n python-k8s-app
kubectl logs -f <pod-name> -n python-k8s-app
kubectl exec -it <pod-name> -n python-k8s-app -- bash

# Scaling
kubectl scale deployment python-k8s-app-deployment --replicas=5 -n python-k8s-app
kubectl get hpa -n python-k8s-app

# Rollback
./scripts/rollback.sh
```

## 📊 Monitoring & Observability

- **Health Checks**: `/api/v1/health`, `/api/v1/health/ready`, `/api/v1/health/live`
- **Metrics**: Prometheus scraping on port 8000
- **Logs**: Structured logging with JSON format
- **Dashboards**: Grafana dashboards for visualization
- **Alerts**: Prometheus alerting rules

## 🔒 Security Features

- Kubernetes secrets for sensitive data
- Network policies for pod communication
- RBAC for role-based access control
- Image vulnerability scanning
- Encrypted storage and communication
- Pod security standards

## 📈 Production Features

- ✅ Zero-downtime deployments
- ✅ Auto-scaling (HPA)
- ✅ Health checks and probes
- ✅ Rolling updates
- ✅ Pod disruption budgets
- ✅ Resource limits and requests
- ✅ Monitoring and alerting
- ✅ CI/CD pipeline
- ✅ Infrastructure as Code
- ✅ Disaster recovery

## 🔧 Troubleshooting Guide

### Common Issues and Solutions

#### 1. **Docker Issues**

**Problem**: Container fails to start
```bash
# Check container logs
docker-compose logs app

# Check if ports are available
netstat -tulpn | grep :8000

# Rebuild containers
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

**Problem**: Database connection issues
```bash
# Check database container
docker-compose logs postgres

# Test database connection
docker-compose exec app python -c "from models.database import engine; print(engine.execute('SELECT 1').scalar())"
```

#### 2. **Kubernetes Issues**

**Problem**: Pods stuck in CrashLoopBackOff
```bash
# Check pod status
kubectl get pods -n python-k8s-app

# Describe pod for details
kubectl describe pod <pod-name> -n python-k8s-app

# Check logs
kubectl logs <pod-name> -n python-k8s-app

# Check events
kubectl get events -n python-k8s-app --sort-by='.lastTimestamp'
```

**Problem**: Service not accessible
```bash
# Check service endpoints
kubectl get endpoints -n python-k8s-app

# Test service connectivity
kubectl run test-pod --image=busybox --rm -it --restart=Never -- wget -qO- http://python-k8s-app-service:80/api/v1/health

# Check ingress
kubectl describe ingress python-k8s-app-ingress -n python-k8s-app
```

**Problem**: Database connection from pods
```bash
# Check database service
kubectl get svc -n python-k8s-app

# Test database connectivity
kubectl run test-db --image=postgres:15-alpine --rm -it --restart=Never -- psql -h postgres-service -U user -d mydb

# Check secrets
kubectl get secrets -n python-k8s-app
kubectl describe secret python-k8s-app-secret -n python-k8s-app
```

#### 3. **Terraform Issues**

**Problem**: Terraform state lock
```bash
# Force unlock (use with caution)
terraform force-unlock <lock-id>

# Check state
terraform state list
terraform state show <resource-name>
```

**Problem**: Resource already exists
```bash
# Import existing resource
terraform import aws_db_instance.postgres <db-instance-id>

# Or remove from state
terraform state rm aws_db_instance.postgres
```

**Problem**: EKS cluster not accessible
```bash
# Update kubeconfig
aws eks update-kubeconfig --region us-west-2 --name python-k8s-app-eks

# Check cluster status
aws eks describe-cluster --name python-k8s-app-eks --region us-west-2
```

#### 4. **Application Issues**

**Problem**: Health checks failing
```bash
# Check health endpoint directly
kubectl exec -it <pod-name> -n python-k8s-app -- curl localhost:8000/api/v1/health

# Check application logs
kubectl logs -f deployment/python-k8s-app-deployment -n python-k8s-app

# Check resource usage
kubectl top pods -n python-k8s-app
```

**Problem**: Database migration issues
```bash
# Check database tables
kubectl exec -it <postgres-pod> -n python-k8s-app -- psql -U user -d mydb -c "\dt"

# Run migrations manually
kubectl exec -it <app-pod> -n python-k8s-app -- python -c "from models.database import Base, engine; Base.metadata.create_all(bind=engine)"
```

#### 5. **Scaling Issues**

**Problem**: HPA not working
```bash
# Check HPA status
kubectl get hpa -n python-k8s-app
kubectl describe hpa python-k8s-app-hpa -n python-k8s-app

# Check metrics server
kubectl top nodes
kubectl top pods -n python-k8s-app

# Check HPA events
kubectl get events -n python-k8s-app --field-selector involvedObject.name=python-k8s-app-hpa
```

**Problem**: Pods not scaling down
```bash
# Check PDB
kubectl get pdb -n python-k8s-app
kubectl describe pdb python-k8s-app-pdb -n python-k8s-app

# Force scale down
kubectl scale deployment python-k8s-app-deployment --replicas=1 -n python-k8s-app
```

### Debugging Commands

```bash
# General debugging
kubectl get all -n python-k8s-app
kubectl describe deployment python-k8s-app-deployment -n python-k8s-app
kubectl logs -f deployment/python-k8s-app-deployment -n python-k8s-app

# Network debugging
kubectl get svc,ingress -n python-k8s-app
kubectl get endpoints -n python-k8s-app

# Resource debugging
kubectl top nodes
kubectl top pods -n python-k8s-app
kubectl describe nodes

# Configuration debugging
kubectl get configmap,secret -n python-k8s-app
kubectl describe configmap python-k8s-app-config -n python-k8s-app
```

### Performance Optimization

```bash
# Check resource usage
kubectl top pods -n python-k8s-app
kubectl top nodes

# Monitor HPA
kubectl get hpa -n python-k8s-app -w

# Check pod distribution
kubectl get pods -n python-k8s-app -o wide

# Monitor events
kubectl get events -n python-k8s-app --sort-by='.lastTimestamp'
```

### Emergency Procedures

```bash
# Quick rollback
kubectl rollout undo deployment/python-k8s-app-deployment -n python-k8s-app

# Scale down for maintenance
kubectl scale deployment python-k8s-app-deployment --replicas=0 -n python-k8s-app

# Emergency access to database
kubectl exec -it <postgres-pod> -n python-k8s-app -- psql -U user -d mydb

# Delete stuck resources
kubectl delete pod <pod-name> -n python-k8s-app --force --grace-period=0
```
