# terraform-azure-governance-policy

Org-standard Terraform wrapper for **Azure Policy**: custom policy definitions and management-group policy assignments. Assignments can have a managed identity, and the module creates that identity's role assignments, as needed for `DeployIfNotExists` / `Modify` policies.

⚠️ **No usable AVM module exists for this resource** as of this writing. `Azure/avm-ptn-policyassignment/azurerm` 0.2.0 pins `hashicorp/azurerm ~> 3.74`, incompatible with this org's `>= 4.0`. This wraps the native `azurerm_policy_definition`, `azurerm_management_group_policy_assignment` and `azurerm_role_assignment` resources directly, following the same conventions as the rest of this org's module set.

Scope: **management group** definitions and assignments only (the org's landing zone design assigns everything at management groups). Policy has no resource group, location or tags, so this module has none of the standard `resource_group_name` / `tags` / `enable_telemetry` inputs.

## Usage

```hcl
module "governance-policy" {
  source = "git::https://github.com/engryinker/terraform-azure-governance-policy.git?ref=v1.0.0"

  policy_definitions = {
    deny_pdns = {
      name                = "Deny-Private-DNS-Zones"
      management_group_id = "/providers/Microsoft.Management/managementGroups/mg-contoso-landingzones"
      display_name        = "Deny private DNS zones"
      policy_rule = jsonencode({
        if   = { field = "type", equals = "Microsoft.Network/privateDnsZones" }
        then = { effect = "Deny" }
      })
    }
  }

  policy_assignments = {
    deny_pdns = {
      name                  = "deny-pdns-zones"
      management_group_id   = "/providers/Microsoft.Management/managementGroups/mg-contoso-landingzones"
      display_name          = "Deny private DNS zones"
      policy_definition_key = "deny_pdns"
    }
  }
}
```

See [`examples/basic`](examples/basic) for a minimal runnable (zero-instance) example.

## Inputs

### `policy_definitions`

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `name` | `string` | yes | Definition name (part of its ID). |
| `management_group_id` | `string` | yes | Full MG resource ID the definition lives at. |
| `display_name` | `string` | yes |  |
| `description` | `string` | no |  |
| `mode` | `string` | no | `All` (default) or `Indexed`. |
| `policy_rule` | `string` | yes | JSON (`jsonencode(...)` / `file(...)`). |
| `parameters` | `string` | no | JSON parameter definitions. |
| `metadata` | `string` | no | JSON. |

### `policy_assignments`

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `name` | `string` | yes | ≤ 24 characters. |
| `management_group_id` | `string` | yes | Assignment scope. |
| `display_name` | `string` | yes |  |
| `description` | `string` | no |  |
| `policy_definition_key` | `string` | one of | Key in `policy_definitions` of this call. |
| `policy_definition_id` | `string` | one of | Any existing definition / initiative ID (e.g. built-ins). |
| `parameters` | `string` | no | JSON: `{"param": {"value": ...}}`. |
| `enforce` | `bool` | no | Default `true`. |
| `not_scopes` | `list(string)` | no | Excluded scopes. |
| `non_compliance_message` | `string` | no |  |
| `identity` | `bool` | no | System-assigned identity (needed for DeployIfNotExists / Modify). |
| `location` | `string` | with identity | Region of the identity. |
| `role_assignments` | `map(object({ scope, role_definition_id_or_name }))` | no | Granted to the assignment's identity. |

The identity running Terraform needs *Resource Policy Contributor* at the management group, plus a role allowed to create role assignments (e.g. *Role Based Access Control Administrator*) at each role assignment scope.

Existing non-compliant resources aren't remediated automatically; create a remediation task when needed (`az policy remediation create`).

## Outputs

- `policy_definitions`, `policy_definition_ids` -- definitions created.
- `policy_assignments` -- assignments created.
- `policy_assignment_principal_ids` -- assignment key => managed identity principal ID.
- `role_assignments` -- role assignments for policy identities.
