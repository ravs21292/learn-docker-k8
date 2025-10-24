#!/bin/bash

# Deployment Script for Python K8s Application
# This script handles the complete deployment process

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION=${AWS_REGION:-us-west-2}
EKS_CLUSTER_NAME=${EKS_CLUSTER_NAME:-python-k8s-app-eks}
EKS_NAMESPACE=${EKS_NAMESPACE:-python-k8s-app}
ECR_REPOSITORY=${ECR_REPOSITORY:-python-k8s-app}
IMAGE_TAG=${IMAGE_TAG:-latest}

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if required tools are installed
    command -v kubectl >/dev/null 2>&1 || { log_error "kubectl is required but not installed. Aborting."; exit 1; }
    command -v aws >/dev/null 2>&1 || { log_error "aws CLI is required but not installed. Aborting."; exit 1; }
    command -v docker >/dev/null 2>&1 || { log_error "docker is required but not installed. Aborting."; exit 1; }
    
    # Check if AWS credentials are configured
    if ! aws sts get-caller-identity >/dev/null 2>&1; then
        log_error "AWS credentials not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

configure_kubectl() {
    log_info "Configuring kubectl for EKS cluster..."
    
    aws eks update-kubeconfig --region $AWS_REGION --name $EKS_CLUSTER_NAME
    
    if kubectl cluster-info >/dev/null 2>&1; then
        log_success "kubectl configured successfully"
    else
        log_error "Failed to configure kubectl"
        exit 1
    fi
}

build_and_push_image() {
    log_info "Building and pushing Docker image..."
    
    # Get AWS account ID
    AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    ECR_REGISTRY="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
    
    # Login to ECR
    aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY
    
    # Build image
    docker build -f docker/Dockerfile -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
    
    # Push image
    docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
    
    log_success "Image built and pushed successfully"
    echo "Image: $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG"
}

deploy_application() {
    log_info "Deploying application to Kubernetes..."
    
    # Create namespace if it doesn't exist
    kubectl create namespace $EKS_NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
    
    # Apply all Kubernetes manifests
    kubectl apply -f k8s/
    
    # Wait for deployment to be ready
    log_info "Waiting for deployment to be ready..."
    kubectl rollout status deployment/python-k8s-app-deployment -n $EKS_NAMESPACE --timeout=300s
    
    log_success "Application deployed successfully"
}

verify_deployment() {
    log_info "Verifying deployment..."
    
    # Check pods
    log_info "Checking pods..."
    kubectl get pods -n $EKS_NAMESPACE
    
    # Check services
    log_info "Checking services..."
    kubectl get services -n $EKS_NAMESPACE
    
    # Check ingress
    log_info "Checking ingress..."
    kubectl get ingress -n $EKS_NAMESPACE
    
    # Get application URL
    INGRESS_HOST=$(kubectl get ingress python-k8s-app-ingress -n $EKS_NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "Not available")
    
    if [ "$INGRESS_HOST" != "Not available" ] && [ ! -z "$INGRESS_HOST" ]; then
        log_success "Application is accessible at: https://$INGRESS_HOST"
        log_info "Health check: curl https://$INGRESS_HOST/api/v1/health"
    else
        log_warning "Ingress not configured or not ready yet"
    fi
}

run_health_checks() {
    log_info "Running health checks..."
    
    # Wait a bit for the application to start
    sleep 10
    
    # Get a pod name
    POD_NAME=$(kubectl get pods -n $EKS_NAMESPACE -l app=python-k8s-app -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
    
    if [ ! -z "$POD_NAME" ]; then
        # Test health endpoint
        if kubectl exec $POD_NAME -n $EKS_NAMESPACE -- curl -f http://localhost:8000/api/v1/health >/dev/null 2>&1; then
            log_success "Health check passed"
        else
            log_warning "Health check failed - application may still be starting"
        fi
    else
        log_warning "No pods found for health check"
    fi
}

cleanup() {
    log_info "Cleaning up temporary resources..."
    # Add any cleanup tasks here if needed
}

# Main execution
main() {
    log_info "Starting deployment process..."
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-build)
                SKIP_BUILD=true
                shift
                ;;
            --skip-push)
                SKIP_PUSH=true
                shift
                ;;
            --image-tag)
                IMAGE_TAG="$2"
                shift 2
                ;;
            --help)
                echo "Usage: $0 [OPTIONS]"
                echo "Options:"
                echo "  --skip-build    Skip Docker image build"
                echo "  --skip-push     Skip Docker image push"
                echo "  --image-tag     Specify image tag (default: latest)"
                echo "  --help          Show this help message"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    # Set up trap for cleanup on exit
    trap cleanup EXIT
    
    # Execute deployment steps
    check_prerequisites
    configure_kubectl
    
    if [ "$SKIP_BUILD" != "true" ]; then
        build_and_push_image
    fi
    
    deploy_application
    verify_deployment
    run_health_checks
    
    log_success "Deployment completed successfully! 🎉"
}

# Run main function
main "$@"