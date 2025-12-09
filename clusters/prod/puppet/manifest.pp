
# Puppet Manifest for prod
# Using voxpupuli/puppet-cassandra structure

node default {
  include stdlib
  include java

  # Configure Cassandra
  class { 'cassandra':
    cluster_name      => 'prod',
    version           => '4.1.3',
    package_ensure    => '4.1.3',
    listen_interface  => 'eth0',
    rpc_interface     => 'eth0',
    seeds             => [],
    dc                => 'us-east-1',
    rack              => 'rack1',
    num_tokens        => 256,
    
    # Advanced: Use external config file managed by OmniCloud
    config_file_mode  => '0644',
    # We disable built-in config generation for yaml/jvm to use our files
    manage_config_file => false,
  }

  # Direct File Management for Config (Allows UI editing to propagate)
  file { '/etc/cassandra/cassandra.yaml':
    ensure  => file,
    content => file('/opt/omnicloud/clusters/prod/conf/cassandra.yaml'),
    owner   => 'cassandra',
    group   => 'cassandra',
    mode    => '0644',
    require => Class['cassandra::install'],
    notify  => Class['cassandra::service'],
  }
  
  file { '/etc/cassandra/jvm.options':
    ensure  => file,
    content => file('/opt/omnicloud/clusters/prod/conf/jvm.options'),
    owner   => 'cassandra',
    group   => 'cassandra',
    mode    => '0644',
    require => Class['cassandra::install'],
    notify  => Class['cassandra::service'],
  }

  # Ensure service is running
  class { 'cassandra::service':
    ensure => running,
    enable => true,
  }
}
