# Ansible MicroK8s Homelab

A comprehensive infrastructure-as-code project for deploying and managing a MicroK8s Kubernetes cluster on a homelab using Ansible automation and GitOps with ArgoCD.

## Overview

This project provides automated deployment and configuration management for a MicroK8s homelab environment consisting of four server nodes:

- **ctrl01**: Ansible controller node - manages configuration and deployments across the cluster
- **k8s1, k8s2, k8s3**: MicroK8s cluster nodes - form the Kubernetes cluster for running containerized workloads

## Architecture

```
Ansible Controller (ctrl01)
    ↓
    └─→ MicroK8s Cluster
         ├── k8s1 (control plane + worker)
         ├── k8s2 (worker)
         └── k8s3 (worker)
         
ArgoCD (GitOps)
    ├── Continuous deployment
    └── Application synchronization
```

## Deployment Methods

### Ansible
Primary deployment mechanism for:
- Initial cluster setup and configuration
- Infrastructure provisioning
- System-level configuration management
- Kubernetes manifests and applications

### ArgoCD
GitOps-based continuous deployment for:
- Declarative application management
- Automated synchronization from Git repositories
- Application rollouts and rollbacks
- Multi-environment deployments

## Quick Start

*(Documentation coming soon)*

## Project Structure

*(Add your project structure here)*

## Requirements

- 4 server nodes with sufficient resources for MicroK8s
- Ansible installed on the controller node
- Network connectivity between all nodes
- SSH access configured for Ansible

## Contributing

*(Add contribution guidelines)*

