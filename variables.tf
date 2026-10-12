variable "policy_definitions" {
  description = "Map of custom policy definitions to create at management group scope, keyed by an arbitrary caller-chosen map key. `policy_rule`, `parameters` and `metadata` are JSON strings (use jsonencode() or file()) so definitions of different shapes can share one map."
  type = map(object({
    name                = string
    management_group_id = string
    display_name        = string
    description         = optional(string)
    mode                = optional(string, "All")
    policy_rule         = string
    parameters          = optional(string)
    metadata            = optional(string)
  }))
  default = {}

  validation {
    condition     = alltrue([for v in var.policy_definitions : can(jsondecode(v.policy_rule)) && (v.parameters == null || can(jsondecode(v.parameters))) && (v.metadata == null || can(jsondecode(v.metadata)))])
    error_message = "policy_rule, parameters and metadata must be valid JSON strings."
  }
}

variable "policy_assignments" {
  description = "Map of policy assignments at management group scope, keyed by an arbitrary caller-chosen map key. Reference a definition from this module call with `policy_definition_key`, or any existing definition / initiative with `policy_definition_id`. Set `identity = true` (and `location`) for DeployIfNotExists / Modify policies, and grant that identity what its remediation needs via `role_assignments`."
  type = map(object({
    name                   = string # <= 24 chars at management group scope
    management_group_id    = string
    display_name           = string
    description            = optional(string)
    policy_definition_key  = optional(string)
    policy_definition_id   = optional(string)
    parameters             = optional(string) # JSON: {"param": {"value": ...}}
    enforce                = optional(bool, true)
    not_scopes             = optional(list(string), [])
    non_compliance_message = optional(string)
    identity               = optional(bool, false) # system-assigned managed identity
    location               = optional(string)      # required when identity = true
    role_assignments = optional(map(object({
      scope                      = string
      role_definition_id_or_name = string
    })), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for v in var.policy_assignments : length(v.name) <= 24])
    error_message = "Management group policy assignment names must be 24 characters or fewer."
  }

  validation {
    condition     = alltrue([for v in var.policy_assignments : (v.policy_definition_key == null) != (v.policy_definition_id == null)])
    error_message = "Each policy assignment must set exactly one of policy_definition_key or policy_definition_id."
  }

  validation {
    condition     = alltrue([for v in var.policy_assignments : !v.identity || v.location != null])
    error_message = "Policy assignments with identity = true must set location."
  }

  validation {
    condition     = alltrue([for v in var.policy_assignments : v.identity || length(v.role_assignments) == 0])
    error_message = "role_assignments require identity = true."
  }

  validation {
    condition     = alltrue([for v in var.policy_assignments : v.parameters == null || can(jsondecode(v.parameters))])
    error_message = "parameters must be a valid JSON string."
  }
}
