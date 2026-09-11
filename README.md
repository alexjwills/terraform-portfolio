# Terraform IAM Portfolio: Alex Wills

A Terraform codification of a hand-built AWS IAM portfolio, covering attribute-based access control (ABAC), permission boundaries, and three patterns (Identity Center, Service Control Policies, cross-account role assumption) that are documented and validated but not deployed, due to a structural Free Tier limitation rather than a skills gap.

This root configuration (`project-2.4/`) ties together the two deployable pieces (ABAC and the permission boundary demo) into a single `apply`/`destroy` unit. The three undeployed patterns live separately in `project-2.3/`.

---

## What's here

### 1. ABAC: tagged IAM roles and a dynamic S3 policy

Three IAM roles (`ABAC-Engineering-Role-tf`, `ABAC-Finance-Role-tf`, `ABAC-Marketing-Role-tf`), each produced by a single reusable module (`modules/abac-role/`) and tagged with their department. All three share **one** IAM policy containing a `Condition` block that compares the requester's `aws:PrincipalTag/department` against the target S3 object's `s3:ExistingObjectTag/department` at request time. The policy itself never names a department; access is determined dynamically, per request, by matching tags.

This directly codifies a hand-built console demonstration using the same condition-based mechanism, rather than a simplified static-per-role stand-in.

**A design decision worth noting explicitly:** this configuration deliberately recreates the pattern fresh (new `-tf`-suffixed resource names) rather than using `terraform import` to adopt the original hand-built resources. Import requires exact pre-existing attribute matching, which is a reverse-engineering exercise rather than a design one, and it risks modifying still-active infrastructure. `terraform import` (or the newer `import {}` block) is the correct tool for genuinely adopting pre-existing production infrastructure into IaC, and would be the natural next step if this pattern needed to take over management of the original resources rather than stand alongside them.

### 2. Permission boundary: delegated power user

A standalone IAM user (`delegated-power-user-tf`) with `PowerUserAccess` attached as its identity policy, capped by a `PowerUserBoundary-tf` permissions boundary restricting effective access to a read-only allowlist (`s3:Get*`, `s3:List*`, `iam:Get*`, `iam:List*`), regardless of what the identity policy itself grants.

Deliberately built as a standalone **user**, not a role. Every other identity in this portfolio is role-based, so isolating the boundary demo on a user removes role-assumption complexity, meaning the boundary mechanism itself is the only variable being demonstrated.

**The core principle this demonstrates:** a permission boundary is a ceiling, not a grant. Effective access is the *intersection* of the identity policy and the boundary. Attaching a broad AWS-managed policy like `PowerUserAccess` doesn't grant broad access if the boundary doesn't also allow it. This was originally proven by hand (`s3:CreateBucket` correctly denied despite `PowerUserAccess` normally permitting it, while read actions correctly succeeded), and the boundary's correct attachment is confirmed here via `aws iam get-user --query 'User.PermissionsBoundary'`.

A permission boundary caps what **one specific IAM entity** can be granted. This is a meaningfully different mechanism from a Service Control Policy (see below), which caps an entire AWS account or Organizational Unit: not one entity, but everyone and everything within scope.

### 3. Documented, not deployed (`project-2.3/`)

Three further patterns from the original hand-built portfolio, written as real, `terraform validate`-passing HCL, deliberately never applied:

- **Service Control Policy**: an `aws_organizations_policy` denying all root-user actions account-wide via a `Condition` on `aws:PrincipalType`. Structurally, this is the account-wide counterpart to the permission boundary above. No `Principal` is needed, since an SCP applies to everyone and everything in scope by default.
- **Cross-account role assumption**: an `aws_iam_role` whose trust policy is structurally identical to every role in this portfolio, with one value changed: the `Principal`'s account ARN points outside this account rather than at it.
- **Identity Center permission sets**: `aws_ssoadmin_permission_set` and `aws_ssoadmin_permission_set_inline_policy`, modelling how access would be defined once, centrally, and provisioned across multiple accounts. This is the pattern most representative of how a larger organisation manages access at scale, beyond per-account IAM.

**Why undeployed:** all three genuinely require an AWS Organization (a multi-account structure) that a Free Tier single-account setup cannot provide. This isn't a partial implementation or a skipped step, but a structural prerequisite that doesn't exist in this environment. `terraform plan` succeeds for all three, confirming the HCL itself is well-formed. `apply` would fail at AWS's API layer specifically because the Organization prerequisite is absent; for the SCP, this would surface as `AWSOrganizationsNotInUseException`. This is a deliberate, stated limitation of the *environment*, not of the code or the understanding behind it.

---

## Design principles applied throughout

- **Account-root trust principal**, used in every role's trust policy in this portfolio (as `arn:aws:iam::<account_id>:root`, supplied via a required variable rather than hardcoded), does **not** grant root privileges. It means any identity within the account is eligible to be considered, with the actual access decision deferred to a separate `sts:AssumeRole` grant in IAM policy. This is a deliberate design choice that keeps the trust policy stable while access can be granted or revoked elsewhere.
- **Modules over duplication**: the ABAC role pattern is written once and called three times with different inputs, rather than copy-pasted per department.
- **A shared policy over per-role policies**, for ABAC specifically, because the access-control logic (tag matching) is identical across departments. Only the data being compared differs, which is exactly what the condition mechanism is for.
- **`plan` validates structure, not deployability.** Several points in this build surfaced the same lesson from different angles: `terraform validate`/`plan` check HCL correctness, not whether a hand-written JSON policy is semantically valid to AWS (a `Principal`/`Principle` typo passed both checks and would only have failed at `apply`), and not whether a resource's real-world prerequisites exist in the target account (the SCP's plan succeeds, but its `apply` would not). Real verification, throughout this portfolio, happens via direct AWS CLI checks against what was actually created, not by trusting a clean `plan` or `apply` log alone.

---

## A note on account identifiers

Every reference to an AWS account ID and the original S3 bucket name has been parameterised as a required Terraform variable (`account_id`, `bucket_name`) with no default value. This keeps the code fully functional and reviewable without publishing real account details. Anyone running this configuration would supply their own values via a `.tfvars` file (already excluded from version control) or the `-var` flag.

---

## Local environment

- Terraform v1.16.1, managed via tfenv
- AWS CLI v2, authenticating via a dedicated IAM user (`terraform-portfolio-admin`), not root, not a personal login
- State: local, for this portfolio's projects. Project 1.4 (not part of this root config) separately builds and tears down a self-managed S3 and DynamoDB remote-state backend, including a real, reproduced lock conflict and a real backend-destruction failure resolved via manual AWS CLI cleanup, documented in the accompanying progress log.