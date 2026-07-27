# Terraform (AWS) — bonus path

The README's mission gives two options for infra: "Deploy this app to a
local cluster (Minikube/Kind) **or** output Terraform for AWS/GCP." The
[`k8s/`](../k8s) manifests are the primary submission (runnable end-to-end
on minikube/kind, which I could actually verify locally). This folder is the
Terraform side, included to show the AWS path — it's written to be correct
and reviewable, but I have not run `terraform apply` against a real AWS
account for this submission, and this file is a template, not a promise:
double check region, sizing, and account-specific values before applying it
anywhere real. It's deliberately scoped to what an app this size needs, not
a full landing-zone build-out.

## What it provisions

- An ECR repository for the container image, with a lifecycle policy that
  expires untagged images after 14 days.
- A Secrets Manager secret for `OPENAI_API_KEY` (value set out-of-band via
  `aws secretsmanager put-secret-value`, never in Terraform state).
- An IAM role for IRSA (IAM Roles for Service Accounts), scoped to
  `secretsmanager:GetSecretValue` on that one secret ARN only — the pod's
  service account assumes this role instead of the node's IAM role, so no
  other workload on the same node can read the secret.

## What it deliberately does NOT provision

Standing up a full EKS cluster from scratch is out of scope for this
exercise's actual review value — most reviewers either have a cluster
already or want to see the minikube/kind path. `eks.tf` documents the module
call you'd add (`terraform-aws-modules/eks/aws`) with the settings this app
needs, as a comment, rather than a resource block that would provision (and
bill for) a real cluster on `apply`.

## Usage

```bash
cd terraform
terraform init
terraform plan -var="aws_region=ap-southeast-2"
```
