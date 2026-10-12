terraform {
  required_version = ">= 1.7.0"
}

module "governance-policy" {
  source = "../.."

  policy_definitions = {} # see README Inputs table for the per-entry schema
  policy_assignments = {}
}
