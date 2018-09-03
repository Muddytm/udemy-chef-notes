#
# Cookbook:: myhaproxy
# Recipe:: default
#
# Copyright:: 2018, The Authors, All Rights Reserved.

all_web_nodes = search("node","role:web")

members = []

# populate members

all_web_nodes.each do |web_node|
  member = {
    # populate ip address and other things
    "hostname" => web_node["hostname"],
    "ipaddress" => web_node["ipaddress"],
    "port" => 80,
    "ssl_port" => 80
  }

  members.push(member)
end

node.default["haproxy"]["members"] = members

# node.default["haproxy"]["members"] = [
#   {
#     "hostname" => "web1", #whatever the fqdn is? i think. might need to recheck on this.
#     "ipaddress" => "192.168.10.43",
#     "port" => 80,
#     "ssl_port" => 80
# },{
#     "hostname" => "web2",
#     "ipaddress" => "192.168.10.44",
#     "port" => 80,
#     "ssl_port" => 80
# }]

include_recipe "haproxy::manual"
