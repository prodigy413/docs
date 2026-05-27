```
以下AWS OrganizationsのOU構成を図で描いてください。

- Managementアカウント
  - AWS IAM Identity Center
  - AWS Organizations
- Security OU
  - Auditアカウント
    - AWS Security Hub
    - AWS Config
    - AWS GuardDuty
- Infrastructure OU
  - Infrastructureアカウント
    - AWS DirectConnect
    - AWS Route 53 Resolver
    - AWS Transit Gateway
    - Bastion Server
    - Proxy Server
- Workload OU
  - Prod OU
    - PRD EC2アカウント
      - AWS EC2
    - PRD Workspacesアカウント
      - AWS Workspaces
    - PRD ROSAアカウント
      - AWS ROSA
  - Non-Prod OU
    - PRD EC2アカウント
      - AWS EC2
    - PRD Workspacesアカウント
      - AWS Workspaces
    - PRD ROSAアカウント
      - AWS ROSA
  - Common OU
    - EVSアカウント
      - AWS EVS
```
