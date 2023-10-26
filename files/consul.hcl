acl {
  enabled        = true
  default_policy = "deny"

  tokens {
    initial_management = "root"
    default            = "root"
  }
}
