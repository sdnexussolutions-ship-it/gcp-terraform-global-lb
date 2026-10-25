# This migration is from the already-applied module.mule_internal_alb state.
# Keep this until the first successful Terraform Cloud apply.
moved {
  from = module.mule_internal_alb
  to   = module.internal_albs["mule"]
}
