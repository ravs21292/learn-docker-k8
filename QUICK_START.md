# Quick Start Guide

Get your Python K8s application up and running in minutes!

## 🚀 Prerequisites

- Docker Desktop
- kubectl
- AWS CLI
- Git

## ⚡ Quick Start (5 minutes)

### 1. Clone and Setup

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/learn-docker-k8.git
cd learn-docker-k8

# Copy environment template
cp env.template .env
# Edit .env with your values
```

### 2. Local Development

```bash
# Start local development environment
cd docker
docker-compose up -d

# Test the application
curl http://localhost:8000/api/v1/health
```

### 3. Deploy to Kubernetes

```bash
# Make scripts executable
chmod +x scripts/*.sh

# Deploy to Kubernetes
./scripts/deploy.sh

# Check deployment status
kubectl get pods -n python-k8s-app
```

### 4. Access Your Application

```bash
# Get application URL
kubectl get ingress -n python-k8s-app

# Test health endpoint
curl https://your-domain.com/api/v1/health
```

## 🔧 Configuration

### Environment Variables

Edit `.env` file with your configuration:

```bash
# Database
DATABASE_URL=postgresql://user:password@localhost:5432/mydb

# AWS Configuration
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_REGION=us-west-2
```

### GitHub Secrets

Add these secrets to your GitHub repository:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

## 📊 Monitoring

Access monitoring dashboards:

```bash
# Prometheus
kubectl port-forward svc/prometheus-service 9090:9090 -n monitoring

# Grafana (admin/admin123)
kubectl port-forward svc/grafana-service 3000:3000 -n monitoring
```

## 🚨 Troubleshooting

### Common Issues

1. **Pod not starting**: Check logs with `kubectl logs <pod-name> -n python-k8s-app`
2. **Database connection**: Verify database pod is running
3. **Image pull issues**: Check ECR permissions

### Rollback

```bash
# Rollback to previous version
./scripts/rollback.sh

# Rollback to specific revision
./scripts/rollback.sh --revision 3
```

## 📚 Next Steps

1. Read the [Complete CI/CD Guide](CI_CD_DEPLOYMENT_GUIDE.md)
2. Set up monitoring alerts
3. Configure custom domains
4. Implement blue-green deployments

## 🆘 Need Help?

- Check the [troubleshooting section](CI_CD_DEPLOYMENT_GUIDE.md#troubleshooting)
- Review Kubernetes events: `kubectl get events -n python-k8s-app`
- Check application logs: `kubectl logs -f deployment/python-k8s-app-deployment -n python-k8s-app`

---

**That's it!** Your application is now running with automated CI/CD! 🎉
