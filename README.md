# MULE ALB — module for_each refactor

This project refactors the *already migrated* `module.mule_internal_alb` to `module.internal_albs["mule"]` using a whole-module `moved` block. The existing MULE resources should move without replacement.

## How to use

Copy these files into the existing repository, preserving `.github/`, `versions.tf`, Terraform Cloud settings, and `.terraform.lock.hcl`. Do not copy local Terraform state. If your actual Terraform Cloud workspace uses other secret-variable names, adjust accordingly. Do not commit secrets.

The root `main.tf` calls a module with `for_each = var.internal_albs`. Sensitive certificates remain separate root variables and are merged into the module config; Terraform Cloud can continue supplying them as sensitive variables. The `lab.auto.tfvars` contains only nonsecret configuration.

Run `terraform fmt -recursive`, `terraform init`, `terraform validate`, then review a **Terraform Cloud plan** before applying. Confirm the existing module resources move and none of the MULE frontend, certificates, NEGs, or backends is destroyed/replaced. Never apply a plan that unexpectedly recreates `10.162.0.12`.

## Important limitations

This is a first-stage refactor to support `for_each`, **not yet a fully generic multi-ALB module**: the child module still contains MULE-specific hardcoded certificate, trust config, backend authentication, and TLS/SNI naming. Adding a second `internal_albs` entry would cause resource-name collisions or wrong certificate/authentication. Do not add another independent ALB until those resources and inputs are generalized and certificates are supplied per instance.

Also, the old root-to-module moved blocks were replaced with a single `module.mule_internal_alb` to `module.internal_albs["mule"]` mapping, because the previous migration was already applied. If that prior migration has NOT been applied in the target workspace, do not use this moved.tf as-is.

Local CLI state may be empty even when Terraform Cloud owns the real resources; use the VCS-linked workspace plan as the source of truth.
