
class profile::base {
  package { ['git', 'curl', 'htop', 'xfsprogs']: ensure => installed }
  service { 'chrony': ensure => running, enable => true }
  # Add users, SSH keys, etc.
}
