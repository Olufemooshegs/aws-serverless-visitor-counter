# Visitor Counter — Serverless on AWS

A production-pattern serverless application built with Terraform and Python.
Live visitor counter that increments on every page load.

## Architecture
Browser → S3 (static site) → API Gateway → Lambda (Python) → DynamoDB


![Architecture](docs/architecture.png)  <!-- add a diagram if you want -->

## Tech Stack

| Layer | Technology |
|---|---|
| Infrastructure as Code | Terraform (≥ 1.5) |
| Cloud provider | AWS (us-east-1) |
| Compute | AWS Lambda (Python 3.12) |
| API | API Gateway (HTTP API v2) |
| Storage | DynamoDB (on-demand) |
| Static hosting | Amazon S3 |
| State backend | S3 + DynamoDB lock |

## Features

- ✅ **Atomic counter** — `ADD` operation in DynamoDB, safe under concurrency
- ✅ **Remote state** — S3 backend with versioning, encryption, and DynamoDB locking
- ✅ **Least-privilege IAM** — Lambda can only touch its own table, only the operations it needs
- ✅ **Modular Terraform** — 4 reusable modules (dynamodb, lambda, api_gateway, s3_website)
- ✅ **CORS** — configured at both API Gateway and Lambda response level
- ✅ **Structured logging** — Lambda logs to CloudWatch with 7-day retention
- ✅ **Fully automated** — one command to deploy, one to tear down

## Project Structure
.
├── terraform/
│ ├── bootstrap/ # Run once — creates S3 + DynamoDB for state
│ ├── modules/ # Reusable building blocks
│ │ ├── dynamodb/
│ │ ├── lambda/
│ │ ├── api_gateway/
│ │ └── s3_website/
│ └── environments/
│ └── dev/ # Dev environment consuming all modules
├── lambda/src/index.py # Python Lambda function
└── frontend/index.html # Static site


## Prerequisites

- AWS account with an IAM user (programmatic access)
- Terraform ≥ 1.5
- AWS CLI v2 configured (`aws configure`)
- Python 3.12 (for local Lambda syntax checks)

## Deployment

### 1. Bootstrap the Terraform backend (run once)

```bash
cd terraform/bootstrap
terraform init
terraform apply
Note the two outputs — you'll need them in the next step.

2. Configure the dev environment
Edit terraform/environments/dev/backend.tf and set the bucket/table names
from the bootstrap outputs.

3. Deploy
cd terraform/environments/dev
terraform init
terraform plan
terraform apply

Terraform will print two URLs:

website_url — open this in a browser

api_url — the raw API endpoint

Testing
curl $(terraform output -raw api_url)
# → {"count": 42}

curl $(terraform output -raw api_url)
# → {"count": 43}
Cleanup
Order matters — destroy the environment first, then the bootstrap:
# 1. Destroy the app
cd terraform/environments/dev
terraform destroy

# 2. Destroy the backend (after removing prevent_destroy from bootstrap/main.tf)
cd terraform/bootstrap
terraform destroy
Design Decisions
HTTP API over REST API — 70% cheaper, lower latency, simpler CORS

On-demand DynamoDB — no capacity planning for unpredictable traffic

Atomic ADD operation — no race conditions under concurrent visitors

Remote state with locking — prevents corruption from concurrent applies

Separate bootstrap — solves the "Terraform can't manage its own backend" problem

Least-privilege IAM — Lambda only has UpdateItem and GetItem on one table

What I Learned
Bootstrapping Terraform state backends

Designing reusable Terraform modules with clear input/output contracts

Serverless patterns on AWS (Lambda + API Gateway + DynamoDB)

CORS in a cross-origin serverless architecture

Least-privilege IAM policy design
License
MIT