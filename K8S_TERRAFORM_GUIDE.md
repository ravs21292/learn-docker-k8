# Kubernetes & Terraform Files Explanation

This document provides detailed explanations of all Kubernetes manifests and Terraform configurations in this project.

## 📋 Table of Contents

1. [Kubernetes Files (k8s/)](#kubernetes-files-k8s)
2. [Terraform Files (terraform/)](#terraform-files-terraform)
3. [Project Architecture](#project-architecture)
4. [Deployment Flow](#deployment-flow)

---

## 🚀 Kubernetes Files (k8s/)

### 1. **namespace.yaml**
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: python-k8s-app
  labels:
    name: python-k8s-app
    environment: production
```

**Purpose**: Creates a dedicated namespace for our application
- **Isolation**: Separates our app resources from other applications
- **Organization**: Groups related resources together
- **Security**: Provides boundary for RBAC policies

### 2. **configmap.yaml**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: python-k8s-app-config
  namespace: python-k8s-app
data:
  APP_NAME: "Python K8s App"
  DEBUG: "false"
  HOST: "0.0.0.0"
  PORT: "8000"
  DATABASE_HOST: "postgres-service"
  DATABASE_PORT: "5432"
  DATABASE_NAME: "mydb"
  REDIS_HOST: "redis-service"
  REDIS_PORT: "6379"
```

**Purpose**: Stores non-sensitive configuration data
- **Configuration Management**: Centralizes app settings
- **Environment Variables**: Injects config into pods
- **Version Control**: Tracks configuration changes
- **Reusability**: Same config across multiple pods

### 3. **secret.yaml**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: python-k8s-app-secret
  namespace: python-k8s-app
type: Opaque
data:
  DATABASE_USER: dXNlcg==  # Base64 encoded 'user'
  DATABASE_PASSWORD: cGFzc3dvcmQ=  # Base64 encoded 'password'
  SECRET_KEY: eW91ci1zZWNyZXQta2V5LWhlcmU=  # Base64 encoded secret
  JWT_SECRET: eW91ci1qd3Qtc2VjcmV0LWtleQ==  # Base64 encoded JWT secret
```

**Purpose**: Stores sensitive data securely
- **Security**: Encrypted at rest and in transit
- **Access Control**: Only accessible by authorized pods
- **Base64 Encoding**: Data is encoded (not encrypted)
- **Separation**: Keeps secrets separate from config

### 4. **postgres/deployment.yaml**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres-deployment
  namespace: python-k8s-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    spec:
      containers:
      - name: postgres
        image: postgres:15-alpine
        env:
        - name: POSTGRES_DB
          value: "mydb"
        - name: POSTGRES_USER
          valueFrom:
            secretKeyRef:
              name: python-k8s-app-secret
              key: DATABASE_USER
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          exec:
            command:
            - pg_isready
            - -U
            - $(POSTGRES_USER)
            - -d
            - $(POSTGRES_DB)
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          exec:
            command:
            - pg_isready
            - -U
            - $(POSTGRES_USER)
            - -d
            - $(POSTGRES_DB)
          initialDelaySeconds: 5
          periodSeconds: 5
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: postgres-pvc
```

**Purpose**: Deploys PostgreSQL database
- **Stateful Workload**: Database with persistent storage
- **Health Checks**: Ensures database is ready before serving traffic
- **Resource Management**: CPU and memory limits
- **Storage**: Persistent volume for data persistence
- **Security**: Uses secrets for credentials

### 5. **postgres/service.yaml**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: postgres-service
  namespace: python-k8s-app
spec:
  selector:
    app: postgres
  ports:
  - port: 5432
    targetPort: 5432
    protocol: TCP
  type: ClusterIP
```

**Purpose**: Exposes PostgreSQL internally
- **Service Discovery**: Provides stable DNS name
- **Load Balancing**: Distributes connections (if multiple replicas)
- **Internal Access**: Only accessible within cluster
- **Port Mapping**: Maps service port to pod port

### 6. **app/deployment.yaml**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: python-k8s-app-deployment
  namespace: python-k8s-app
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0  # Zero-downtime deployment
  selector:
    matchLabels:
      app: python-k8s-app
  template:
    spec:
      containers:
      - name: python-k8s-app
        image: python-k8s-app:latest
        ports:
        - containerPort: 8000
        env:
        - name: DATABASE_URL
          value: "postgresql://$(DATABASE_USER):$(DATABASE_PASSWORD)@postgres-service:5432/mydb"
        envFrom:
        - configMapRef:
            name: python-k8s-app-config
        - secretRef:
            name: python-k8s-app-secret
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /api/v1/health/live
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /api/v1/health/ready
            port: 8000
          initialDelaySeconds: 5
          periodSeconds: 5
        startupProbe:
          httpGet:
            path: /api/v1/health
            port: 8000
          initialDelaySeconds: 10
          periodSeconds: 5
          failureThreshold: 10
      initContainers:
      - name: wait-for-postgres
        image: postgres:15-alpine
        command: ['sh', '-c', 'until pg_isready -h postgres-service -p 5432 -U $(DATABASE_USER); do echo waiting for postgres; sleep 2; done;']
```

**Purpose**: Deploys Python application
- **High Availability**: 3 replicas for redundancy
- **Zero-Downtime**: Rolling update strategy
- **Health Checks**: Multiple probe types for reliability
- **Init Container**: Waits for database to be ready
- **Resource Management**: CPU and memory limits
- **Configuration**: Uses ConfigMap and Secret

### 7. **app/service.yaml**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: python-k8s-app-service
  namespace: python-k8s-app
spec:
  selector:
    app: python-k8s-app
  ports:
  - port: 80
    targetPort: 8000
    protocol: TCP
  type: ClusterIP
---
apiVersion: v1
kind: Service
metadata:
  name: python-k8s-app-service-nodeport
  namespace: python-k8s-app
spec:
  selector:
    app: python-k8s-app
  ports:
  - port: 80
    targetPort: 8000
    nodePort: 30080
    protocol: TCP
  type: NodePort
```

**Purpose**: Exposes Python application
- **Internal Access**: ClusterIP for internal communication
- **External Access**: NodePort for direct access (development)
- **Load Balancing**: Distributes traffic across replicas
- **Service Discovery**: Stable DNS name

### 8. **ingress.yaml**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: python-k8s-app-ingress
  namespace: python-k8s-app
  annotations:
    kubernetes.io/ingress.class: "alb"
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/healthcheck-path: /api/v1/health
    alb.ingress.kubernetes.io/healthcheck-interval-seconds: '15'
    alb.ingress.kubernetes.io/ssl-redirect: '443'
spec:
  rules:
  - host: your-domain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: python-k8s-app-service
            port:
              number: 80
```

**Purpose**: Exposes application to internet
- **Load Balancer**: AWS Application Load Balancer
- **SSL Termination**: HTTPS support
- **Health Checks**: ALB health monitoring
- **Domain Routing**: Routes traffic based on hostname
- **Production Ready**: Internet-facing configuration

### 9. **hpa.yaml** (Horizontal Pod Autoscaler)
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: python-k8s-app-hpa
  namespace: python-k8s-app
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: python-k8s-app-deployment
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 10
        periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
      - type: Percent
        value: 50
        periodSeconds: 60
      - type: Pods
        value: 2
        periodSeconds: 60
```

**Purpose**: Auto-scales application based on metrics
- **CPU Scaling**: Scales when CPU > 70%
- **Memory Scaling**: Scales when memory > 80%
- **Gradual Scaling**: Prevents rapid scaling changes
- **Min/Max Replicas**: Maintains availability bounds
- **Stabilization**: Prevents flapping

### 10. **pdb.yaml** (Pod Disruption Budget)
```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: python-k8s-app-pdb
  namespace: python-k8s-app
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: python-k8s-app
```

**Purpose**: Ensures minimum availability during disruptions
- **High Availability**: Maintains at least 2 pods running
- **Rolling Updates**: Prevents too many pods being down
- **Node Maintenance**: Protects during node updates
- **Disaster Recovery**: Ensures service continuity

---

## 🏗️ Terraform Files (terraform/)

### 1. **main.tf** - Main Infrastructure Configuration

#### **VPC Module**
```hcl
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.project_name}-vpc"
  cidr = var.vpc_cidr

  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway = true
  enable_vpn_gateway = false
  enable_dns_hostnames = true
  enable_dns_support = true
}
```

**Purpose**: Creates VPC with public/private subnets
- **Network Isolation**: Isolated network environment
- **Multi-AZ**: Spans multiple availability zones
- **NAT Gateway**: Private subnets can access internet
- **DNS Support**: Internal DNS resolution

#### **EKS Module**
```hcl
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = "${var.project_name}-eks"
  cluster_version = var.kubernetes_version

  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access = true

  eks_managed_node_groups = {
    main = {
      name = "main"
      instance_types = var.node_instance_types
      capacity_type  = "ON_DEMAND"
      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size
      disk_size = 50
    }
  }
}
```

**Purpose**: Creates EKS cluster with managed node groups
- **Managed Kubernetes**: AWS-managed control plane
- **Auto Scaling**: Node group auto-scaling
- **Security**: Private subnets for nodes
- **Monitoring**: CloudWatch integration

#### **RDS PostgreSQL**
```hcl
resource "aws_db_instance" "postgres" {
  identifier = "${var.project_name}-postgres"

  engine         = "postgres"
  engine_version = "15.4"
  instance_class = var.db_instance_class

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = "mydb"
  username = var.db_username
  password = var.db_password

  vpc_security_group_ids = [aws_security_group.postgres.id]
  db_subnet_group_name   = aws_db_subnet_group.postgres.name

  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  skip_final_snapshot = true
  deletion_protection = false
}
```

**Purpose**: Creates managed PostgreSQL database
- **Managed Service**: AWS RDS handles maintenance
- **High Availability**: Multi-AZ deployment option
- **Backups**: Automated backups with retention
- **Security**: Encrypted storage and network isolation
- **Scaling**: Auto-scaling storage

#### **ECR Repository**
```hcl
resource "aws_ecr_repository" "app" {
  name                 = "${var.project_name}-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
```

**Purpose**: Creates Docker image repository
- **Image Storage**: Secure Docker image storage
- **Vulnerability Scanning**: Automatic security scanning
- **Version Control**: Image versioning and tagging
- **Access Control**: IAM-based access management

### 2. **variables.tf** - Input Variables

```hcl
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "python-k8s-app"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnets" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnets" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}
```

**Purpose**: Defines configurable parameters
- **Flexibility**: Easy to modify without changing code
- **Reusability**: Same code for different environments
- **Documentation**: Self-documenting parameters
- **Validation**: Type checking and constraints

### 3. **outputs.tf** - Output Values

```hcl
output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_name" {
  description = "The name/id of the EKS cluster"
  value       = module.eks.cluster_name
}

output "vpc_id" {
  description = "ID of the VPC where the cluster is deployed"
  value       = module.vpc.vpc_id
}

output "db_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.postgres.endpoint
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.app.repository_url
}
```

**Purpose**: Exposes important values after deployment
- **Integration**: Other systems can use these values
- **Documentation**: Shows what was created
- **Automation**: Scripts can use these outputs
- **Monitoring**: Track resource creation

---

## 🏛️ Project Architecture

### **High-Level Architecture**

```
┌─────────────────────────────────────────────────────────────────┐
│                        Internet                                 │
└─────────────────────┬───────────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────────┐
│                AWS Application Load Balancer                    │
│                    (ALB Ingress)                               │
└─────────────────────┬───────────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────────┐
│                    AWS EKS Cluster                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │   Python App    │  │   Python App    │  │   Python App    │ │
│  │     Pod 1       │  │     Pod 2       │  │     Pod 3       │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
│           │                   │                   │            │
│           └───────────────────┼───────────────────┘            │
│                               │                               │
│  ┌─────────────────────────────▼─────────────────────────────┐ │
│  │              PostgreSQL Pod (Local Dev)                  │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────────┐
│                    AWS RDS PostgreSQL                          │
│                  (Production Database)                         │
└─────────────────────────────────────────────────────────────────┘
```

### **Data Flow**

1. **User Request** → Internet
2. **Load Balancer** → AWS ALB (SSL termination, health checks)
3. **Ingress Controller** → Routes to appropriate service
4. **Service** → Load balances across pods
5. **Pod** → Python FastAPI application
6. **Database** → PostgreSQL (RDS in production, local in dev)

### **Deployment Flow**

1. **Code Push** → GitHub
2. **CI/CD** → GitHub Actions
3. **Build** → Docker image creation
4. **Push** → ECR repository
5. **Deploy** → EKS cluster
6. **Update** → Rolling update of pods
7. **Verify** → Health checks and monitoring

---

## 🔄 Deployment Flow

### **1. Infrastructure Provisioning**
```bash
terraform init
terraform plan
terraform apply
```

### **2. Application Deployment**
```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/secret.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/postgres/
kubectl apply -f k8s/app/
kubectl apply -f k8s/ingress.yaml
kubectl apply -f k8s/hpa.yaml
kubectl apply -f k8s/pdb.yaml
```

### **3. CI/CD Pipeline**
1. **Code Push** → Triggers GitHub Actions
2. **Test** → Run unit tests and linting
3. **Build** → Create Docker image
4. **Push** → Upload to ECR
5. **Deploy** → Update Kubernetes deployment
6. **Verify** → Health checks and monitoring

### **4. Monitoring & Scaling**
- **Prometheus** → Collects metrics
- **Grafana** → Visualizes metrics
- **HPA** → Auto-scales based on CPU/memory
- **CloudWatch** → AWS native monitoring

This architecture provides a robust, scalable, and production-ready platform for your Python application with PostgreSQL database, fully automated deployment, and comprehensive monitoring.

