#!/bin/bash

# Rollback Script for Python K8s Application
# This script handles rolling back to the previous version

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
EKS_NAMESPACE=${EKS_NAMESPACE:-python-k8s-app}
DEPLOYMENT_NAME=${DEPLOYMENT_NAME:-python-k8s-app-deployment}

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
    
    # Check if kubectl is installed
    command -v kubectl >/dev/null 2>&1 || { log_error "kubectl is required but not installed. Aborting."; exit 1; }
    
    # Check if deployment exists
    if ! kubectl get deployment $DEPLOYMENT_NAME -n $EKS_NAMESPACE >/dev/null 2>&1; then
        log_error "Deployment $DEPLOYMENT_NAME not found in namespace $EKS_NAMESPACE"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

show_deployment_history() {
    log_info "Deployment history:"
    kubectl rollout history deployment/$DEPLOYMENT_NAME -n $EKS_NAMESPACE
}

rollback_to_previous() {
    log_info "Rolling back to previous version..."
    
    # Rollback to previous version
    kubectl rollout undo deployment/$DEPLOYMENT_NAME -n $EKS_NAMESPACE
    
    # Wait for rollback to complete
    log_info "Waiting for rollback to complete..."
    kubectl rollout status deployment/$DEPLOYMENT_NAME -n $EKS_NAMESPACE --timeout=300s
    
    log_success "Rollback completed successfully"
}

rollback_to_specific_revision() {
    local revision=$1
    log_info "Rolling back to revision $revision..."
    
    # Rollback to specific revision
    kubectl rollout undo deployment/$DEPLOYMENT_NAME --to-revision=$revision -n $EKS_NAMESPACE
    
    # Wait for rollback to complete
    log_info "Waiting for rollback to complete..."
    kubectl rollout status deployment/$DEPLOYMENT_NAME -n $EKS_NAMESPACE --timeout=300s
    
    log_success "Rollback to revision $revision completed successfully"
}

verify_rollback() {
    log_info "Verifying rollback..."
    
    # Check deployment status
    log_info "Deployment status:"
    kubectl get deployment $DEPLOYMENT_NAME -n $EKS_NAMESPACE
    
    # Check pods
    log_info "Pod status:"
    kubectl get pods -n $EKS_NAMESPACE -l app=python-k8s-app
    
    # Check rollout status
    log_info "Rollout status:"
    kubectl rollout status deployment/$DEPLOYMENT_NAME -n $EKS_NAMESPACE
}

run_health_checks() {
    log_info "Running health checks after rollback..."
    
    # Wait a bit for the application to start
    sleep 10
    
    # Get a pod name
    POD_NAME=$(kubectl get pods -n $EKS_NAMESPACE -l app=python-k8s-app -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
    
    if [ ! -z "$POD_NAME" ]; then
        # Test health endpoint
        if kubectl exec $POD_NAME -n $EKS_NAMESPACE -- curl -f http://localhost:8000/api/v1/health >/dev/null 2>&1; then
            log_success "Health check passed after rollback"
        else
            log_warning "Health check failed - application may still be starting"
        fi
    else
        log_warning "No pods found for health check"
    fi
}

show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --revision REVISION    Rollback to specific revision number"
    echo "  --history             Show deployment history and exit"
    echo "  --help                Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                    # Rollback to previous version"
    echo "  $0 --revision 3       # Rollback to revision 3"
    echo "  $0 --history          # Show deployment history"
}

# Main execution
main() {
    local revision=""
    local show_history=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --revision)
                revision="$2"
                shift 2
                ;;
            --history)
                show_history=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Check prerequisites
    check_prerequisites
    
    # Show history if requested
    if [ "$show_history" = true ]; then
        show_deployment_history
        exit 0
    fi
    
    # Show current deployment history
    show_deployment_history
    
    # Perform rollback
    if [ ! -z "$revision" ]; then
        rollback_to_specific_revision $revision
    else
        rollback_to_previous
    fi
    
    # Verify rollback
    verify_rollback
    
    # Run health checks
    run_health_checks
    
    log_success "Rollback completed successfully! 🎉"
}

# Run main function
main "$@"