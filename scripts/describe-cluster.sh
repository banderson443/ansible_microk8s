#!/bin/bash

# describe-cluster.sh - Comprehensive MicroK8s cluster description via Ansible
# Usage: ./describe-cluster.sh [target_host]

TARGET_HOST=${1:-"k8s1.home.arpa"}
KUBECTL_CMD="microk8s kubectl"

echo "========================================"
echo "MicroK8s Cluster Description"
echo "Target: $TARGET_HOST"
echo "Date: $(date)"
echo "========================================"

# Helper function to run kubectl commands via Ansible
run_kubectl() {
    local cmd="$1"
    local description="$2"
    
    echo
    echo "--- $description ---"
    ansible "$TARGET_HOST" -m ansible.builtin.shell -a "$KUBECTL_CMD $cmd" 2>/dev/null | \
        sed '1d' | sed '/^$/d' | sed 's/^[^ ]* | [^ ]* | [^ ]* >>//'
}

# Cluster Info
run_kubectl "cluster-info" "Cluster Information"

# Node Information
run_kubectl "get nodes -o wide" "Node Details"
run_kubectl "describe nodes" "Node Description (Resource Usage & Conditions)"

# System Pods and Services
run_kubectl "get pods -A -o wide" "All Pods Across Namespaces"
run_kubectl "get services -A" "All Services"

# Storage
run_kubectl "get pv,pvc -A" "Persistent Volumes and Claims"
run_kubectl "get storageclass" "Storage Classes"

# Networking
run_kubectl "get ingress -A" "Ingress Controllers"
run_kubectl "get networkpolicies -A" "Network Policies"

# Workloads
run_kubectl "get deployments -A" "Deployments"
run_kubectl "get daemonsets -A" "DaemonSets"
run_kubectl "get statefulsets -A" "StatefulSets"
run_kubectl "get jobs,cronjobs -A" "Jobs and CronJobs"

# Configuration
run_kubectl "get configmaps -A" "ConfigMaps"
run_kubectl "get secrets -A" "Secrets (names only)"

# RBAC
run_kubectl "get clusterroles --no-headers | wc -l" "Cluster Roles Count"
run_kubectl "get clusterrolebindings --no-headers | wc -l" "Cluster Role Bindings Count"
run_kubectl "get roles -A --no-headers | wc -l" "Roles Count"
run_kubectl "get rolebindings -A --no-headers | wc -l" "Role Bindings Count"

# Resource Quotas and Limits
run_kubectl "get resourcequota -A" "Resource Quotas"
run_kubectl "get limitrange -A" "Limit Ranges"

# Custom Resources
run_kubectl "get crd" "Custom Resource Definitions"

# Events (recent)
run_kubectl "get events --sort-by='.lastTimestamp' -A | tail -20" "Recent Events (Last 20)"

# Namespace Summary
run_kubectl "get namespaces" "Namespaces"

# MicroK8s Specific
echo
echo "--- MicroK8s Add-ons Status ---"
ansible "$TARGET_HOST" -m ansible.builtin.shell -a "microk8s status" 2>/dev/null | \
    sed '1d' | sed '/^$/d' | sed 's/^[^ ]* | [^ ]* | [^ ]* >>//'

# Top resource consumers (if metrics-server is available)
echo
echo "--- Resource Usage (if metrics available) ---"
ansible "$TARGET_HOST" -m ansible.builtin.shell -a "$KUBECTL_CMD top nodes" 2>/dev/null | \
    sed '1d' | sed '/^$/d' | sed 's/^[^ ]* | [^ ]* | [^ ]* >>//' || echo "Metrics server not available"

ansible "$TARGET_HOST" -m ansible.builtin.shell -a "$KUBECTL_CMD top pods -A | head -10" 2>/dev/null | \
    sed '1d' | sed '/^$/d' | sed 's/^[^ ]* | [^ ]* | [^ ]* >>//' || echo "Pod metrics not available"

# Cluster health summary
echo
echo "--- Cluster Health Summary ---"
run_kubectl "get componentstatus" "Component Status"

# Pod status summary
echo
echo "--- Pod Status Summary ---"
ansible "$TARGET_HOST" -m ansible.builtin.shell -a "$KUBECTL_CMD get pods -A --no-headers | awk '{print \$4}' | sort | uniq -c" 2>/dev/null | \
    sed '1d' | sed '/^$/d' | sed 's/^[^ ]* | [^ ]* | [^ ]* >>//'

echo
echo "========================================"
echo "Cluster description complete!"
echo "========================================"
