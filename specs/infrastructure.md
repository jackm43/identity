# Infrastructure Specification

## Overview

Single AWS EC2 instance hosting Ory Kratos via Docker Compose. External access is provided through Cloudflare Tunnel, eliminating the need for public HTTPS exposure. The instance uses an EBS volume for data persistence.

## Components

### EC2 Instance
- **AMI**: Ubuntu 24.04 LTS (latest)
- **Instance Type**: t3.small (2 vCPU, 2GB RAM)
- **Key Pair**: "Github and SSH Key" (existing)

### Security Group
- **Inbound**:
  - SSH (22) from user IP only
  - No public 443 needed (Cloudflare Tunnel originates connections outbound)
- **Outbound**: All traffic allowed

### EBS Volume
- Root volume: 20GB gp3
- Stores Docker volumes for Kratos and PostgreSQL data

## Terraform Requirements

### Provider Configuration
```hcl
provider "aws" {
  profile = "terraform"
  region  = "ap-southeast-2"
}
```

### Resources
- `aws_instance` - EC2 instance with user_data for Docker installation
- `aws_security_group` - SSH access restrictions
- `aws_ebs_volume` (optional) - Additional persistent storage if needed

### Outputs
- `instance_public_ip` - For SSH access
- `instance_id` - For AWS console reference

### User Data Script
Install on boot:
- Docker Engine
- Docker Compose plugin
- Create directories: `/opt/kratos`, `/opt/postgres`

## Acceptance Criteria

- [ ] `terraform validate` passes
- [ ] `terraform apply` completes without errors
- [ ] SSH access works: `ssh -i "GitHub and SSH Key.pem" ubuntu@<instance_ip>`
- [ ] Docker running: `docker --version` returns successfully
- [ ] Docker Compose available: `docker compose version` returns successfully
- [ ] Directories exist: `/opt/kratos`, `/opt/postgres`
