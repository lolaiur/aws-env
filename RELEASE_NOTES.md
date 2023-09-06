# RELEASE NOTES
- Forti is now deployable into production via deploy_oig = true

- Config will push via user data from var.os_pass & var.os_user

- Forti TF still doesn't work due to provider not being conditional & requires working api token?

- Forti API token is passed statically via local but can be added to params.tfvars

- TFLint will fail because of unused variables but they are still good!
