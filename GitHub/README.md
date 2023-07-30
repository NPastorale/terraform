# Instructions

These are the instructions to properly utilise this partiular Terraform code.

## GitHub authentication

To be allowed to run this code a GitHub token is needed.

Add an `auth.auto.tfvars` file with the following content:

```
github_token = "ghp_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
```

## Docker Hub authentication

There is a `docker_token` variable that is used to populate a secret for the repositories that need access to push images to Docker Hub. That should also be added to the `auth.auto.tfvars` file
