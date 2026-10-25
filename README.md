# MULE Regional Internal HTTPS ALB — module refactor

This is a **state-address refactor** of the previous map-based MULE configuration, not a request to recreate infrastructure. The complete ALB stack lives in `modules/internal-https-alb/`; root `main.tf` calls it. Existing SBX/DEV backend maps, `/test1` and `/test2` routing, frontend and backend mTLS, and certificate inputs are preserved.

## Migration safety

1. Back up the current Terraform state/workspace and commit the current working configuration.
2. Replace the four root files and add `moved.tf`, `outputs.tf`, and `modules/internal-https-alb/`. Remove old root resource blocks; do not retain both old and new definitions.
3. Ensure certificate PEM variables remain supplied securely in Terraform Cloud (not in git). `lab.auto.tfvars` contains no certificate private keys.
4. Run `terraform fmt -recursive`, `terraform init`, `terraform validate`, and `terraform plan`.
5. Confirm the plan shows `has moved to` entries for the existing MULE resources, with **no destroy/create/replacement** for the MULE frontend IP, proxy, forwarding rule, TLS policies, certificates, NEGs, or backend services. The frontend must remain `10.162.0.12`.
6. If non-MULE resources still exist in state from the prior configuration, Terraform may propose destroying them because they are absent here. Review these separately and ensure they are truly disposable. Do not apply until that list is approved.
7. In Terraform Cloud VCS workflow, commit to a feature branch, review speculative plan, and merge only after review.

`moved.tf` covers the MULE root resource addresses. The mapping for `for_each` resources applies to all keyed instances. This design keeps the original resource names and map keys inside the child module to minimize churn.

## Adding backends

Add a NEG entry, health check, backend service, and URL map path rule to `lab.auto.tfvars`. The module will instantiate resources using `for_each`; you do not need to duplicate resource blocks. Additional independent ALBs can use a second invocation of this module, but the hard-coded MULE certificate/trust/auth resources currently inside the module must first be generalized to support multiple independent instances without name collisions.

## Known boundaries

The module intentionally preserves existing TLS SNI, SAN, authentication mappings, and certificate resource names. It is a faithful refactor, not yet a fully generic multi-ALB implementation. Do not commit secrets, state files, or plan files. Run Terraform against your real provider/workspace to verify behavior; this package was not tested with a Terraform binary.
