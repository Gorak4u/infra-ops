
class role::cassandra_node {
  include profile::base
  include profile::cassandra
  # include profile::monitoring
}
