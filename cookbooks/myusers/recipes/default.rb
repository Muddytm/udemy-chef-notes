#
# Cookbook:: myusers
# Recipe:: default
#
# Copyright:: 2018, The Authors, All Rights Reserved.

# user "user1" do
#   comment
#   uid
#   gid "1"
#   home
#   shell
#   action :create
# end
#
# group "group1" do
#   members "user1"
# end

search("users", "platform:centos").each do |user_data|
  user user_data["id"] do
    comment user_data["comment"]
    uid user_data["uid"]
    gid user_data["gid"]
    home user_data["home"]
    shell user_data["shell"]
  end
end

include_recipe "myusers::groups"
