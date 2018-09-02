#
# Cookbook:: apache
# Recipe:: default
#
# Copyright:: 2018, The Authors, All Rights Reserved.
include_recipe "cookbook::recipe" # to run recipe "recipe" from cookbook "cookbook"

include_recipe "apache::server" # to run server.rb. Don't put .rb after! 
