resource "azurerm_policy_definition" "this" {
  for_each = var.policy_definitions

  name                = each.value.name
  policy_type         = "Custom"
  mode                = each.value.mode
  display_name        = each.value.display_name
  description         = each.value.description
  management_group_id = each.value.management_group_id
  policy_rule         = each.value.policy_rule
  parameters          = each.value.parameters
  metadata            = each.value.metadata
}

resource "azurerm_management_group_policy_assignment" "this" {
  for_each = var.policy_assignments

  name                 = each.value.name
  management_group_id  = each.value.management_group_id
  display_name         = each.value.display_name
  description          = each.value.description
  policy_definition_id = each.value.policy_definition_key != null ? azurerm_policy_definition.this[each.value.policy_definition_key].id : each.value.policy_definition_id
  parameters           = each.value.parameters
  enforce              = each.value.enforce
  not_scopes           = each.value.not_scopes
  location             = each.value.location

  dynamic "identity" {
    for_each = each.value.identity ? [1] : []
    content {
      type = "SystemAssigned"
    }
  }

  dynamic "non_compliance_message" {
    for_each = each.value.non_compliance_message == null ? [] : [each.value.non_compliance_message]
    content {
      content = non_compliance_message.value
    }
  }
}

locals {
  assignment_role_assignments = merge([
    for ak, a in var.policy_assignments : {
      for rk, r in a.role_assignments : "${ak}/${rk}" => merge(r, { assignment_key = ak })
    }
  ]...)
}

# Rights for the assignment's managed identity (what DeployIfNotExists /
# Modify remediation deploys with).
resource "azurerm_role_assignment" "this" {
  for_each = local.assignment_role_assignments

  scope                            = each.value.scope
  role_definition_id               = startswith(each.value.role_definition_id_or_name, "/") ? each.value.role_definition_id_or_name : null
  role_definition_name             = startswith(each.value.role_definition_id_or_name, "/") ? null : each.value.role_definition_id_or_name
  principal_id                     = azurerm_management_group_policy_assignment.this[each.value.assignment_key].identity[0].principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}
