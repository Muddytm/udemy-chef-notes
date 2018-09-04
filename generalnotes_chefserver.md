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

section 12, lecture 65 gives information on running `chef-client` on a schedule. supermarket.chef.io/cookbooks/chef-client has more info.

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

after making these changes to myhaproxy, by the way, we gotta update the version, then do `berks install` and `berks upload` to upload to the chef server.


# environments

environments are networks of nodes that adhere to different rules based on the environment. in general this means that we can test new versions in some environments, while others have "locked" versions of cookbooks, usually being production

production environment = what the user sees and interacts with - is generally locked down to a version of the chef infrastructure

acceptance environment = an environment that is essentially testing for production - can be adjusted and tested with without any real penalty to the end user, since it's not production

by default, every node is assigned to "\_default" environment.

let's create an environment. first check the help command: `knife environment --help`

our preferred method is to create an environment locally and then upload it.

first, make an environments folder for the environment to live. not strictly necessary, but a good idea.

then, make a file (say, production.rb), and make it look like this (for example):

```ruby
name "production"
description "where production code is run"

cookbook "apache", "= 0.2.1"
cookbook "myhaproxy", "= 1.0.0"
```

versions are a big deal - again, any time you make a change to a cookbook that changes its functionality, push it to git with an upgraded version!

now we want to upload the environment to our chef server: `knife environment from file environments/production.rb`

now check out `knife environment list` for your information.

you can set nodes to an environment with `knife node environment set web1 production`, `knife node environment set load-balancer production`.

again, the nodes don't know that they're now in an environment yet - you'll need to converge both by sshing in and running `sudo chef-client`.

exercise: make an acceptance environment with no cookbook restrictions, upload it to the chef server, add web2 to the environment, and then converge web2 so it knows it's in the environment. steps:

1. make an acceptance.rb and put it in the environments directory.
2. make it like so:

```ruby
name "acceptance"
description "where we test code"
```

(note: no cookbook restrictions)

3. run `knife environment from file environments/acceptance.rb`
4. run `knife node environment set web2 acceptance`
5. ssh into web2, and then run `sudo chef-client`
6. done!

made a change to the myhaproxy default.rb that necessitates that all nodes added to the load-balancer's node list MUST be in the same environment as the load-balancer itself. that's friggin cool. now the line looks like this:

```ruby
all_web_nodes = search("node","role:web AND chef_environment:#{node.chef_environment}")
```

since the myhaproxy version is higher now due to the version requirement of the production environment, we must `berks install` and then `berks upload` so that chef is happy.

any time we update versions of cookbooks or add new ones to an environment's cookbook requirements, we need to upload the environment with `knife environment from file environments/blahblahblah.rb`


# data bags

data bags hold information that is not tied to a single node. they can hold users, groups, whatever. the method of holding data in a data bag is JSON.

we can also encrypt data bags! wooooo.

for this class example, we'll be uploading data bags from the chef-repo directory. i'm actually going to make a data_bags directory in the main directory of this repo, so check that out.

first create one on the chef server by running `knife data bag create users`.

now i'm gonna make a JSON file in data_bags/users, check it out. I want these to belong to the "users" data bag, as created a second ago.

now run `knife data bag from file users data_bags/users/user1.json data_bags/users/user2.json`

some info commands:
- `knife data bag show users`
- `knife data bag show users/user1`
- `knife search users "*:*"`
- `knife search users "platform:centos"`
- `knife search users "comment:*2"`

now let's try groups. I made a group named group1.json, specifying to have user1 and user2 as members.

let's run `knife data bag create groups`, then `knife data bag from file groups data_bags/groups/group1.json`. boom, done.

let's create a new cookbook called "myusers": `chef generate cookbook cookbooks/myusers`

i then edited default.rb to include this:

```ruby
search("users", "platform:centos").each do |user_data|
  user user_data["id"] do
    comment user_data["comment"]
    uid user_data["uid"]
    gid user_data["gid"]
    home user_data["home"]
    shell user_data["shell"]
  end
end
```

this means, for every user that uses centos in the users databag, create a new "user" resource by the name of user_data["id"], with that information. cool. i can then add this to an environment's run list, in this case web.rb:

```ruby
run_list "recipe[myusers]","recipe[workstation]","recipe[apache]"
```

now we want to `berks install` and `berks upload` for the new cookbook "myusers", and then `knife role from file web.rb` to update the role.

now, all nodes in this environment will run this user creation cookbook that dynamically creates users according to the users data bag. hot dang.

going through the exercise in section 16, lecture 85:

1. we create 3 new user json files, with the same format as user1 and user2 (but with appropriately differing data)
2. we create a group with those users' names in the members list.
3. let's add all the users to the users data bag: `knife data bag from file users anthony.json julia.json gordon.json`
4. we'll then add the group to the groups data bag: `knife data bag from file groups chefs.json`
5. we'll then modify the "myusers" default.rb to include the bit where we automate group creation from the groups data bag. we create groups.rb as a separate recipe to include in default.rb.
6. now we want to include this in a role - turns out, the teacher wanted us to make a new role, to put in a role. roleception. or something. anyways, we create a new role named base.rb and put "recipe[myusers]" in the run_list.
7. we'll upload the role and all other roles we put "role[base]" in (`knife role from file roles/web.rb roles/base.rb roles/load-balancer.rb`), and include this role in the web role (which is the one he wanted it in)
8. we'll want to update the myusers cookbook version, as usual. VERY IMPORTANT TO DO SO :)

that was a doozy. check out this lecture again if you need a do-over.

the last bit! encrypting data bags. the purpose of this is generally to hide plaintext data so that they don't appear in git, chef server, etc.

run `openssl rand -base64 512 | tr -d '\r\n' > secret-key` to store a secret key that we'll be using.

run `knife data bag create secret-users --secret-file secret-key` to make "secret-users" encrypted with that key.

run `knife data bag from file secret-users data_bags/users/julia.json --secret-file secret-key` to store julia.json there

if you run `knife data bag show secret-users` then you'll see the encrypted julia.json.

if you run `knife data bag show secret-users julia --secret-file secret-key` then everything shows up as normal! groovy.

client.pem is a secret key found in /etc/chef that is unique to that node - consider using it.

look into `knife vault`, as it is a shortcut to using client.pem as encryption.


# we're done!

teacher is very proud of me. he's very proud of YOU, whoever you are, reading this.

look into chef automate, and chef habitat.

the best way to learn chef, is to use chef - so i better get around to using it.

check out learn.chef.io!

look up "The Joy of Automating" for chef.

devops podcast for chef: "Foodfight"

check out github.com/chef

maybe go to chefconf? 
