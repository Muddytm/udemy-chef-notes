# Commands implied to be run as root :) see generalnotes_localmachine.md for notes for the first half of the class.

# Chef server general

Woo! Part 2! Everything up until now has been done on a local machine. Now we'll be looking at storing stuff on the chef server and pulling stuff from it.

Chef shines in managing many nodes.

Load Balancer: forwards incoming web requests to other nodes. It balances the loads it receives. Capiche?

Steps to setting up a load balancer:

1. create the haproxy (load balancer) cookbook
2. provision the instance
3. install chef
4. copy the haproxy cookbook
5. apply the cookbook

your machine can access the chef server and send it cookbooks and things, and then the chef server sends those to all the nodes, including web servers and a load balancer.

(this is all in section 10, lecture 50. very useful information)


# the manage chef interface, chef-repo, and knife

you'll need to create an account, and then either join or create a new organization.

get the chef starter kit. this is the "chef repo" and allows you to communicate with your chef server.

put your cookbooks into this chef-repo cookbooks dir.

`cat .chef/knife.rb` to get some neat info.

`knife client list` to get the validator token, i.e. calebhawkins-validator.

`knife` is the primary function for interacting with the chef server.

`knife cookbook list` lists the cookbooks you've uploaded.

`knife cookbook upload apache` where "apache" is the cookbook i want to upload.

online, you can look at permissions and things for the cookbooks.

bootstrapping your node: `knife bootstrap FQDN -x USER -P PWD --sudo -N node_name`

FQDN = fully qualified domain name
USER = username
PWD = bet you can't guess what this is
--sudo = sudo flag
node_name = ...node name.

teacher is using vagrant and typed `knife bootstrap localhost --ssh-port 2222 --ssh-user vagrant --sudo --identity-file /pathto/privatekey -N web1`

this bootstrapped the node and gave it the name of web1 (just for instance)

run `knife node show web1` to give details for that node.

run `knife node run_list add web1 "recipe[apache],recipe[cookbook]"` to add this run_list to web1

`vagrant ssh` in, and run `sudo chef-client` to start the client.

the above bootstrapping instructions can be found in section 10, lecture 55.


# custom cookbooks and the chef supermarket

in the supermarket, you can find community cookbooks. these are nice, since you don't need to write them yourself and usually they are tested by the creator, meaning little work on the user's end.

hey, remember the datadog cookbook? that can be found in the supermarket.

the supermarket is at supermarket.chef.io!

cookbooks found here list the amount of followers and supported platforms, which is neat.

more details can be found by clicking on the cookbook name and using your eyeballs.

the "usage" section is important as it tells you how to use it.

what if we want to call a supermarket cookbook as a dependency? let's try it with community cookbook "haproxy".

See myhaproxy cookbook metadata.rb - i added this line: `depends "haproxy", "= 2.0.0"`

check default.rb of myhaproxy for more example use of this particular community cookbook


# berkshelf

sounds like "bookshelf" sort of

`cat Berksfile` will show something like:

```
source 'https://supermarket.chef.io'

metadata
```

`berks install` will install any dependencies needed, as indicated by metadata.rb

`berks upload` uploads the dependencies to the cookbook

(frozen) means that nothing is done, since the version has not changed.

haproxy, by the way, helps to build a load balancer. this is pretty cool.

so, full steps for how to set up a load balancer, using vagrant:

- do `vagrant ssh-config` to get load balancer port (2222 in this case)
- `knife bootstrap localhost --ssh-port 2222 --ssh-user vagrant --sudo --identity-file /Users/chawkins/chef-repo/.vagrant/machines/load-balancer/virtualbox/private_key -N load-balancer --run-list "recipe[myhaproxy]"`
- `vagrant ssh load-balancer` to ssh into load-balancer vm
- check to make sure it worked, in the example he did `curl localhost` and then checked to see if the webpage could be accessed


# nodes

we need to bootstrap a new node.

IMPORTANT: for stuff like AWS, sometimes we want to do unattended installs, so check that out on docs.chef.io. it's basically when a node bootstraps itself. reeeeally important here.

let's bootstrap a new node and add it to the load balancer we set up (section 12, lecture 63):

- (again, using vagrant)
- `vagrant ssh-config` to get info for whatever node, let's say...web2
- `knife bootstrap localhost --ssh-port 2200 --ssh-user vagrant --sudo --identity-file /Users/chawkins/chef-repo/.vagrant/machines/web2/virtualbox/private_key -N web2 --run-list "recipe[workstation],recipe[apache]"`
- ssh in and `sudo chef-client` to converge again
- exit and go over to the myhaproxy cookbook and add some values for this new node (added to the myhaproxy cookbook default.rb, in this repo)
- after that, UPDATE THE VERSION and then `berks install` and then `berks upload`.
- `knife cookbook show myhaproxy` and `knife cookbook list` give some more info for what you've done.
- ssh to load-balancer and `sudo chef-client` to converge again. if successful, the node attribute should be added.
- check video to see what this looks like. the cookbooks in this repo are not entirely representative of what the ones for this example should look like, since I messed with them a bit for practice

`knife node show web1` where web1 is the name, is useful for getting information on a node and verifying if the info is correct.

allows for stuff like `knife node show web1 -a ipaddress` and `knife node show web1 -a hostname`

section 12, lecture 65 gives information on running chef-client on a schedule. supermarket.chef.io/cookbooks/chef-client has more info.

node["chef_client"]["interval"] and node ["chef_client"]["splay"] set the time interval between automated chef-client runs, and add a random amount of time to the interval, respectively. these can be changed, but also have default values.

to make this happen, you'll want to add `depends "chef-client", "= [version]"` to metadata.rb.

then you'll want to add `node.default["chef_client"]["interval"] = "300"` and `node.default["chef_client"]["interval"] = "60"` to default.rb, to set what you want these variables to be (300 and 60 are arbitrary, change them to whatever you want)

then add `include_recipe "chef-client::default"` after that.

go the same level as your berksfile, then do `berks install` to get your dependencies, and then `berks upload`.

finally you'll want to go to your chef-repo and do `knife node run_list set load-balancer "recipe[mychef-client],recipe[myhaproxy]"` to get load-balancer to behave by these timings


# roles

roles can be used to designate certain kinds of run-lists and things to be applied to specific types of nodes.

there are multiple methods for creating and assigning roles.

if you downloaded the starter kit, there is a directory called roles with a file named stater.rb. this is a nice template for how to create a role:

- name = name of role
- description = description of role
- run_list = run_list for role
- override_attributes = to be added to node objects, for any node that has this role.
- default_attributes = same? Not 100% clear on the differences.


so, let's create a new role web.rb in our roles directory:

```ruby
name "web"
description "web server role"
run_list "recipe[workstation]","recipe[apache]"
default_attributes "apache-test" => {
  "attribute1" => "hello from attribute 1",
  "attribute2" = > "you're great!"
}
```

then, you wanna upload this role with `knife role from file roles/web.rb`

`knife node run_list set web1 "role[web]"` to set the run_list for web1 to the role run_list.

at this point, you'll wanna ssh in to web1 and then `sudo chef-client` to converge.

after converging, the role will be applied to web1! you can check with `knife node show web1`.

`knife role --help` gives additional options for role creation, including writing one with the JSON format :D

section 13, lecture 69 is an exercise in creating a load-balancer role. pretty simple - written below as load-balancer.rb:

```ruby
name "load-balancer"
description "role for proxy servers"
run_list "recipe[myhaproxy]"
```

we then `knife role from file roles/load-balancer.rb` and then `knife node run_list set load-balancer "role[load-balancer]"`

ssh into load-balancer and `sudo chef-client` to converge, at which point the role is set.

check out section 13, lecture 70 for more info on converging with `knife ssh` instead of sshing in to run `chef-client`. it's great for testing convergence with looooots of vms that are all under one role.


# search and indexing

use search to query data indexed on the chef server.

searching can be used our load balancer by allowing it to dynamically add nodes to its node list.

format: `knife search INDEX (client, node, role, environment, data_bags) "key:value"`

example: `knife search node "*:*"` will return information for ALL nodes.

example: `knife search node "*:*" -a ipaddress` will return the ip addresses for ALL nodes.

example: `knife search node "name:web1"` will return information for web1 node.

example: `knife search node "role:web"` will return information for nodes with the web role.

example: `knife search role "*:*"` will return information for ALL roles.

example `knife search node "role:web AND recipes:apache"` returns information for nodes that have the web role and have apache recipe(s) in the run_list

all information given is updated as of the last convergence for each node.

see myhaproxy default.rb for an example of how to dynamically fetch things like ip addresses, based on search/indexing. i left the original version in (commented out) but the new version is wayyyyyyyy better. this way, search is used to populate a variable with specific information, then this information is stored as node objects, which is called from with the haproxy recipe later on.
