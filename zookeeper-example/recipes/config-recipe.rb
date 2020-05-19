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

hab_config "zookeeper.default" do
  config({
  zookeeper: {
    clientPort: 2020
}})
end
