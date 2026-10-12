output "policy_definitions" {
  description = "Map (same keys as var.policy_definitions) of every attribute of each policy definition created."
  value       = azurerm_policy_definition.this
}

output "policy_definition_ids" {
  description = "Map (same keys as var.policy_definitions) of policy definition resource IDs."
  value       = { for k, v in azurerm_policy_definition.this : k => v.id }
}

output "policy_assignments" {
  description = "Map (same keys as var.policy_assignments) of every attribute of each policy assignment created."
  value       = azurerm_management_group_policy_assignment.this
}

output "policy_assignment_principal_ids" {
  description = "Map (same keys as var.policy_assignments, identity-enabled ones only) of each assignment's managed identity principal ID."
  value       = { for k, v in azurerm_management_group_policy_assignment.this : k => v.identity[0].principal_id if length(v.identity) > 0 }
}

output "role_assignments" {
  description = "Map, keyed `<assignment key>/<role assignment key>`, of every role assignment created for policy identities."
  value       = azurerm_role_assignment.this
}
