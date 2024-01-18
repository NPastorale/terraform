## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_github"></a> [github](#provider\_github) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [github_actions_secret.actions_secret](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_secret) | resource |
| [github_actions_variable.actions_variable](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_variable) | resource |
| [github_branch.main](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/branch) | resource |
| [github_branch_default.default](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/branch_default) | resource |
| [github_branch_protection.main_protection](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/branch_protection) | resource |
| [github_repository.repository](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_actions_secrets"></a> [actions\_secrets](#input\_actions\_secrets) | A map of secrets for the repository | `map(any)` | `{}` | no |
| <a name="input_actions_variables"></a> [actions\_variables](#input\_actions\_variables) | A map of variables for the repository | `map(any)` | `{}` | no |
| <a name="input_archived"></a> [archived](#input\_archived) | The archived status | `string` | `false` | no |
| <a name="input_repository_description"></a> [repository\_description](#input\_repository\_description) | The repository description | `string` | `""` | no |
| <a name="input_repository_name"></a> [repository\_name](#input\_repository\_name) | The repository name | `string` | n/a | yes |
| <a name="input_status_checks"></a> [status\_checks](#input\_status\_checks) | A list of required status checks | `list(any)` | `[]` | no |
| <a name="input_visibility"></a> [visibility](#input\_visibility) | Whether the repository is private or public | `string` | `"public"` | no |

## Outputs

No outputs.
