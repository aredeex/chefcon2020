ohai 'reload' do
  action :nothing
end

hab_install 'install habitat' do
  license 'accept'
  bldr_url node['zookeeper']['builder_url'] if node['zookeeper']['builder_url']
end

hab_sup 'default'do
  license 'accept'
end

hab_package node['zookeeper']['origin'] do
  version node['zookeeper']['version'] if node['zookeeper']['version']
  channel node['zookeeper']['channel'] if node['zookeeper']['channel']
  bldr_url node['zookeeper']['builder_url'] if node['zookeeper']['builder_url']
  action :upgrade
  notifies :restart, 'service[zookeeper]', :delayed
end

systemd_unit 'zookeeper.service' do
  content <<-EOU
  [Unit]
  Description=ZooKeeper Service
  Documentation=http://zookeeper.apache.org
  Requires=network.target
  After=network.target

  [Service]
  Type=forking
  User=root
  Group=root
  ExecStart=/bin/hab pkg exec #{node['zookeeper']['origin']} zkServer.sh start /etc/zookeeper/conf/zoo.cfg
  ExecStop=/bin/hab pkg exec #{node['zookeeper']['origin']} zkServer.sh stop /etc/zookeeper/conf/zoo.cfg
  ExecReload=/bin/hab pkg exec #{node['zookeeper']['origin']} zkServer.sh restart /etc/zookeeper/conf/zoo.cfg
  Environment=ZOOMAIN=org.apache.zookeeper.server.quorum.QuorumPeerMain
  Environment=ZOOCFGDIR=/etc/zookeeper/conf
  Environment=ZOOCFG=/etc/zookeeper/conf/zoo.cfg
  Environment=ZOO_LOG_DIR=/var/log/zookeeper
  Environment=ZOO_LOG4J_PROP=INFO,ROLLINGFILE
  Environment=JMXLOCALONLY=true
  [Install]
  WantedBy=default.target
  EOU
  action [:create, :enable]
end

service 'zookeeper' do
  action :nothing
end

directory node['zookeeper']['data_path'] do
  owner 'root'
  group 'root'
  mode '0755'
  recursive true
  action :create
end

directory '/etc/zookeeper/conf' do
  owner 'root'
  group 'root'
  mode '0755'
  recursive true
  action :create
end

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

template '/etc/zookeeper/conf/log4j.properties' do
  source 'zookeeper/log4j.properties.erb'
  owner 'root'
  group 'root'
  mode '0644'
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

# Generate server id based on the hostname number
template "#{node['zookeeper']['data_path']}/myid" do
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

# Get aliased zkcli in for local testing
template '/bin/zkcli' do
  source 'zookeeper/zkcli.erb'
  owner 'root'
  group 'root'
  mode '0755'
end

# Disable swap per the docs for zookeeper
sysctl_param 'vm.swappiness' do
  value 0
end
