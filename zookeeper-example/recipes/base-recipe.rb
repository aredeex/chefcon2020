ohai 'reload' do
  action :nothing
end

apt_update 'zookeeper_example_apt_update' do
  action :nothing
end

packages = ['libzookeeper-java', 'zookeeper', 'zookeeperd']
packages.each do |pkg|
  package pkg do
    action :install
    version node['zookeeper']['version'] if node['zookeeper']['version']
    notifies :update, 'apt_update[zookeeper_example_apt_update]', :before
  end
end

# Sets up zookeeper cluster from an array of fqdns from hostlist
directory node['zookeeper']['data_path'] do
  owner 'zookeeper'
  group 'zookeeper'
  mode '0755'
  recursive true
  action :create
  not_if { node['zookeeper']['data_path'] == '/var/lib/zookeeper' }
end

# Copy over default data if dataDir is non-default before config change
bash 'copy_data' do
  user 'root'
  code <<-EOH
  cp -a /var/lib/zookeeper/* #{node['zookeeper']['data_path']}
  EOH
  not_if { node['zookeeper']['data_path'] == '/var/lib/zookeeper' }
  not_if { ::File.file?("#{node['zookeeper']['data_path']}/myid") }
  notifies :restart, 'service[zookeeper]', :delayed
end
#
# Update zoo config
template '/etc/zookeeper/conf/zoo.cfg' do
  source 'zookeeper/zoo.cfg.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    server_list: node['zookeeper']['hostlist'],
    purgeInterval: node['zookeeper']['purgeInterval'],
    data_path: node['zookeeper']['data_path']
  )
  notifies :restart, 'service[zookeeper]', :delayed
end

# Generate server id based on the hostname number
template '/etc/zookeeper/conf/myid' do
  source 'zookeeper/myid.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    lazy do
      { idnum: node['fqdn'].split('.')[0].gsub(/\D/, '').gsub(/^0/, '') }
    end
  )
  notifies :restart, 'service[zookeeper]', :delayed
  notifies :reload, 'ohai[reload]', :before
end

service 'zookeeper' do
  action [:enable, :start]
end

# Disable swap per the docs for zookeeper
sysctl_param 'vm.swappiness' do
  value 0
end

# Add zkCli to path
link '/usr/bin/zkcli' do
  to '/usr/share/zookeeper/bin/zkCli.sh'
end
link '/usr/bin/zkEnv.sh' do
  to '/usr/share/zookeeper/bin/zkEnv.sh'
end
