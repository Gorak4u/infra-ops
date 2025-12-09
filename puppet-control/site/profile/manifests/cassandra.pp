
class profile::cassandra {
  # 1. OS Tuning
  sysctl { 'vm.max_map_count': value => '1048575' }
  sysctl { 'net.ipv4.tcp_keepalive_time': value => '60' }

  class { 'limits':
    config => {
      'cassandra' => { 'nofile' => { 'soft' => '100000', 'hard' => '100000' }, 'memlock' => { 'soft' => 'unlimited', 'hard' => 'unlimited' } }
    }
  }

  # 2. Config Injection (From Hiera)
  $cluster_name = lookup('cassandra::cluster_name')
  $seeds        = lookup('cassandra::seeds')
  $heap         = lookup('cassandra::heap')
  
  # 3. Install
  class { 'cassandra':
    cluster_name => $cluster_name,
    seeds        => $seeds,
    heap         => $heap,
    package_ensure => lookup('cassandra::version'),
    service_ensure => running,
    service_enable => true,
    # Use template if complex config needed
    # config_file_content => template('profile/cassandra/cassandra.yaml.erb')
  }
}
