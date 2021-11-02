# s3 Backend Configuration

1. Comment out code in `backend.tf`
2. Run `terraform apply` to create the s3 bucket and dynamoDB locking table
3. Uncomment code in `backend.tf`
4. Run `terraform init` - this will push current state to s3 under a `global/` prefix

```bash
$ terraform init

Initializing the backend...
Do you want to copy existing state to the new backend?
  Pre-existing state was found while migrating the previous "local" backend to the
  newly configured "s3" backend. No existing state was found in the newly
  configured "s3" backend. Do you want to copy this state to the new "s3"
  backend? Enter "yes" to copy and "no" to start with an empty state.

  Enter a value: yes


Successfully configured the backend "s3"! Terraform will automatically
use this backend unless the backend configuration changes.
...
```
