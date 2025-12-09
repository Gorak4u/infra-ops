
# Entry Point
node default {
  # Look up classes defined in Hiera 'classes' array or simple role logic
  $role = lookup('role', String, 'first', 'base')
  
  if $role == 'cassandra_node' {
    include role::cassandra_node
  } else {
    include profile::base
  }
}
