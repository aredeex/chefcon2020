# Test list of servers for a zookeeper cluster
# node.default['zookeeper']['hostlist'] = ['hostname-array-here']
# node.default['zookeeper']['version'] = '3.4.9-3'
node.default['zookeeper']['channel'] = 'stable'
node.default['zookeeper']['origin'] = 'core/zookeeper'
node.default['zookeeper']['zookeeper']['origin'] = 'core/zookeeper'
# Time in hours that the logs/snapshots are kept.  Default of 3 copies are kept and
# can be changed w/ the autopurge.snapRetainCount setting.
node.default['zookeeper']['purgeInterval'] = '1'

# Where zookeeper keeps it's logs and data
node.default['zookeeper']['data_path'] = '/var/lib/zookeeper'

node.default['package_name'] = ''
node.default['config'] = {"zookeeper": {"clientPort": "2020"}}
