package "tree" do
  action :install
end

package "ntp" do # this whole block is the same as just "package 'ntp'"
  action :install
end

file "/etc/motd" do
  content "This server is the property of Caleb Hawkins
  HOSTNAME: #{node['hostname']}
  IPADDRESS: #{node['ipaddress']}
  CPU: #{node['cpu']['0']['mhz']}
  MEMORY: #{node['memory']['total']}
"
  action :create # If you wanna be explicit about what you're doing?
  owner "root" # These two determine permissions
  group "root" # :)
end

service "ntpd" do
  action [ :enable, :start ]
end

# if you just type "package 'ntp'", then that will take the default action (install)

# keep in mind, these are executed in an ordered manner, top to bottom.
