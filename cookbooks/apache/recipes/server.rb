#
# Cookbook:: apache
# Recipe:: server
#
# Copyright:: 2018, The Authors, All Rights Reserved.

package "httpd" do
  action :install # we don't have to put this line or the next line (install is default action), but we wanna be explicit.
end

# file "/var/www/html/index.html" do
#   content "<h1>Hello, world!</h1>
#   <h2>IPADDRESS: #{node['ipaddress']}</h2>
#   <h2>HOSTNAME: #{node['hostname']}</h2>
# "
# end

template "/var/www/html/index.html" do
  source "index.html.erb"
  action :create
end

template "/etc/motd" do
  source "motd.erb" # source goes to the templates directory and looks for this name.
  action :create
end

# ^ what this does is basically the same as "file" but it's from a template.

service "httpd" do # services have no default action...weird, right?
  action [ :enable, :start ] # this will first enable, and THEN start
end
