ohai 'reload' do
  action :nothing
end

hab_sup 'default' do
  license 'accept'
end

hab_package node['package_name'] do
  version node['version'] if node['version']
  channel node['channel'] if node['channel']
  bldr_url node['bldr_url'] if node['bldr_url']
  auth_token node['auth_token'] if node['auth_token']
  action :upgrade
end

hab_service node['package_name'] do
  strategy node['strategy'] if node['strategy']
end

directory '/var/log/zookeeper' do
  owner 'hab'
  group 'hab'
  mode '0755'
  action :create
end

directory node['zookeeper']['data_path'] do
  owner 'hab'
  group 'hab'
  mode '0755'
  recursive true
  action :create
end

directory '/etc/zookeeper/conf' do
  owner 'hab'
  group 'hab'
  mode '0755'
  recursive true
  action :create
end

# Update zoo config
template '/etc/zookeeper/conf/zoo.cfg' do
  source 'zookeeper/zoo.cfg.erb'
  owner 'hab'
  group 'hab'
  mode '0644'
  variables(
    server_list: node['zookeeper']['hostlist'],
    purgeInterval: node['zookeeper']['purgeInterval'],
    data_path: node['zookeeper']['data_path']
  )
  notifies :reload, "hab_service[#{node['package_name']}]", :delayed
end

template '/etc/zookeeper/conf/log4j.properties' do
  source 'zookeeper/log4j.properties.erb'
  owner 'hab'
  group 'hab'
  mode '0644'
  notifies :reload, "hab_service[#{node['package_name']}]", :delayed
end

# Generate server id based on the hostname number
template "#{node['zookeeper']['data_path']}/myid" do
  source 'zookeeper/myid.erb'
  owner 'hab'
  group 'hab'
  mode '0644'
  variables(
    lazy do
      { idnum: node['fqdn'].split('.')[0].gsub(/\D/, '').gsub(/^0/, '') }
    end
  )
  notifies :reload, 'ohai[reload]', :before
  notifies :reload, "hab_service[#{node['package_name']}]", :delayed
end

# Get aliased zkcli in for local testing
template '/bin/zkcli' do
  source 'zookeeper/zkcli.erb'
  owner 'hab'
  group 'hab'
  mode '0755'
end

# Disable swap per the docs for zookeeper
sysctl_param 'vm.swappiness' do
  value 0
end
