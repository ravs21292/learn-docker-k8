# Deployment Guide

This guide will walk you through deploying the Python K8s application to AWS EKS with zero-downtime deployments.

## Prerequisites

1. **AWS CLI** configured with appropriate permissions
2. **kubectl** installed and configured
3. **Docker** installed
4. **Terraform** installed (v1.0+)
5. **Git** for version control

## Quick Start

### 1. Local Development

```bash
# Clone the repository
git clone <your-repo-url>
cd learn-docker-k8

# Start local development environment
cd docker
docker-compose up -d

# Test the application
curl http://localhost:8000/api/v1/health
```

### 2. AWS Infrastructure Setup

```bash
# Navigate to terraform directory
cd terraform

# Copy and configure variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Deploy infrastructure
terraform apply
```

### 3. Configure kubectl for EKS

```bash
# Update kubeconfig
aws eks update-kubeconfig --region us-west-2 --name python-k8s-app-eks

# Verify connection
kubectl get nodes
```

### 4. Deploy Application to Kubernetes

```bash
# Apply all Kubernetes manifests
kubectl apply -f k8s/

# Verify deployment
kubectl get pods -n python-k8s-app
kubectl get services -n python-k8s-app
```

### 5. Set up CI/CD Pipeline

1. **Fork this repository** to your GitHub account
2. **Configure GitHub Secrets**:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
3. **Push to main branch** to trigger deployment

## Production Deployment

### Zero-Downtime Deployment Strategy

The application is configured for zero-downtime deployments using:

1. **Rolling Updates**: Kubernetes rolling update strategy
2. **Health Checks**: Liveness, readiness, and startup probes
3. **Pod Disruption Budgets**: Ensures minimum availability
4. **Horizontal Pod Autoscaler**: Auto-scaling based on metrics

### Monitoring and Logging

1. **Prometheus**: Metrics collection
2. **Grafana**: Visualization dashboards
3. **AWS CloudWatch**: Log aggregation
4. **Health Endpoints**: Application health monitoring

### Security Best Practices

1. **Secrets Management**: Kubernetes secrets for sensitive data
2. **Network Policies**: Restrict pod-to-pod communication
3. **RBAC**: Role-based access control
4. **Image Scanning**: ECR vulnerability scanning

## Troubleshooting

### Common Issues

1. **Pod CrashLoopBackOff**:
   ```bash
   kubectl describe pod <pod-name> -n python-k8s-app
   kubectl logs <pod-name> -n python-k8s-app
   ```

2. **Database Connection Issues**:
   ```bash
   kubectl get pods -n python-k8s-app
   kubectl exec -it <postgres-pod> -n python-k8s-app -- psql -U user -d mydb
   ```

3. **Service Not Accessible**:
   ```bash
   kubectl get services -n python-k8s-app
   kubectl get ingress -n python-k8s-app
   ```

### Rollback Procedure

```bash
# Rollback to previous version
./scripts/rollback.sh

# Or manually
kubectl rollout undo deployment/python-k8s-app-deployment -n python-k8s-app
```

## Scaling

### Horizontal Scaling

```bash
# Scale application pods
kubectl scale deployment python-k8s-app-deployment --replicas=5 -n python-k8s-app

# Check HPA status
kubectl get hpa -n python-k8s-app
```

### Vertical Scaling

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

## Cost Optimization

1. **Use Spot Instances** for non-critical workloads
2. **Right-size Resources** based on actual usage
3. **Enable Cluster Autoscaler** for dynamic scaling
4. **Use Reserved Instances** for predictable workloads

## Security Considerations

1. **Network Policies**: Implement network segmentation
2. **Pod Security Standards**: Use security contexts
3. **Image Security**: Regular vulnerability scanning
4. **Secrets Rotation**: Regular secret updates
5. **RBAC**: Principle of least privilege

## Backup and Disaster Recovery

1. **Database Backups**: Automated RDS snapshots
2. **Configuration Backups**: Git-based configuration management
3. **Multi-Region Setup**: Cross-region replication
4. **Recovery Procedures**: Documented rollback procedures
