# Service resource

service "ntp" do
  action [ :enable, :start ]
end
