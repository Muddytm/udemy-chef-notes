# IMPORTANT: most chef and chef-client command line stuff is implied to be run as root. Use sudo, or log in as root.


# general

sudo chef-client --local-mode setup.rb (for instance) just runs the code for that machine.

`chef generate` can be used to generate cookbooks, recipes, etc. Type `chef generate` for a list.

docs.chef.io is a good place for resource research.


# cookbook notes

a cookbook defines a scenario, such as everything needed to install and configure MySQL, and then it contains all of the components that are required to support that scenario.

so cookbooks contain not only recipes, but things that the recipes need to function, like configs, etc.

cookbooks specify the resources to use and the order in which they are to be applied.

common components of a cookbook: README, metadata (version, dependencies, etc.), recipes, testing directories (spec + test)

`chef generate cookbook cookbooks/workstation` where cookbooks is the cookbooks directory, to make the cookbook

Berksfile = handles dependencies for cookbooks - we'll see more of this when we work with the chef server

chefignore = like gitignore, used to designate what we wanna ignore

metadata.rb = includes stuff like name, version (important), license, description, etc. We can also store DEPENDENCIES here. You can call other cookbooks from here, which is neat.

README.md = what it says on the tin.

WHEN MAKING COMMITS TO GIT, INCREMENT THE VERSION IN METADATA.RB :)


# chef-client

chef-client is the agent that actually runs stuff.

`chef-client -z --runlist "cookbook::recipe"` ... (i.e. "apache::server")

--runlist = -r

`chef-client -z -r "recipe[apache::server]"` <- syntax for running more than one thing at once

`chef-client -z -r "recipe[apache::server],recipe[cookbook::recipe]"` <- running multiple. No spaces FYI

see default.rb in apache cookbook for info on how to use include_recipe.

`chef-client -z -r "recipe[apache]"` <- shorthand for running default.rb in apache.

`chef-client -z -r "recipe[apache],recipe[cookbook]"` <- Running both defaults back to back

oh yeah, and `-zr` works the same as `-z -r`. :)


# ohai

literally just running `ohai` gets you a BUNCH of system information. It's all in a JSON too.

you can also run stuff like `ohai memory` or `ohai cpu/0/mhz`, which also returns info in JSON.

this is the equivalent of puppet facts! :)

example of using ohai node variables in recipes/setup.rb!

also see server.rb in the apache cookbook for another example.


# templates

these are resources - Embedded Ruby (ERB) templates

the resource is set up as "template" and then calls the ERB as a source

templates will generally replace the "file" resource we've been using.

ERB logic is essentially an if-else statement.

ERB example:

```ruby
<% if (50 + 50) == 100 %>
50 + 50 = <%= 50 + 50>
<% else %>
At some point all of MATH I learned in school changed.
<% end %>
```

the teacher of this course likes to remind us that <%= looks like an angry squid. Kinda does.

the angry squid <%= is useful at the beginning of the ERB tags, as it actually posts the following string. see motd.erb in apache templates

check server.rb in apache cookbook for some more info on how to use templates.

you can also pass variables into templates:

```ruby
template "/etc/motd" do
  source "motd.erb"
  variables(
  :name => 'Caleb Hawkins'
  )
  action :create
end
```

then in the template, put in `NAME: <%= @name %>` to call this up.


# cookbook_file

cookbook_file = template, but with no variables. it's completely static. example of how to use in a recipe:

```ruby
cookbook_file 'file_dir' do
  source 'index.html'
  action :create
end
```

to make one, run `chef generate file cookbooksdir/cookbook/ index.hmtl` (as an example)

format of the file itself is like a template, but it has no variables or anything.


# remote_file

remote_file = a method of getting files from online. in the below example, it's an image.

```ruby
remote_file "example/path/file.jpg" do
  source "online_file_source.jpg"
end

template "example/path/index.html" do
  source "index.html.erb"
end
```

index.html.erb then references "file.jpg", and since we've downloaded that via remote_file, it is displayed on the page.


# execute resource

execute resource lets you run other scripts as part of the chef recipe.

there is a bash resource in chef:

```ruby
bash "script_name" do
  user "root"
  code "mkdir /var/www/mysites/ && chown -R apache /var/www/mysites"
  not_if "[ -d /var/www/mysites/ ]"
  not_if do
    File.directory?("/var/www/mysites")
  end
  only_if "somethingsomethingsomething (you get the idea)"
end
```

the script function shown above is an example one that creates a directory and sets the owner as "apache" recursively.

you can add "guard" conditions, listed above as not_if and only_if, to specify if the code should be run. doesn't have to be bash, can be ruby, as seen with the second not_if

now for the execute resource:

```ruby
execute "run a script" do
  user "root"
  command <<-EOH
  mkdir -p /var/www/mysites/ /
  chown -R apache /var/www/mysites/
  EOH
  not_if blahblahblah
end

execute "run_script" do
  user "root"
  command "./myscript.ssh"
  not_if blahblahblah
end
```

the first option is running a script *in* the recipe, and the second is running the script from its own file.

directory resource:

```ruby
directory "/var/www/mysites" do
  owner "apache"
  recursive true
end
```

this does the same thing as the above scripts - creates the directory if it doesn't exist, and then sets the owner as apache recursively if not already done.

this is the preferred way of doing the above function. when possible, use chef resources, and be careful with bash resources.


# users and groups

create a user on a system using a resource:

```ruby
user "user1" do
  comment "user1"
  uid 123
  home "/home/user1"
  shell "/bin/bash"
end
```

create a group on a system using a resource:

```ruby
group "admins" do
  members "user1" # (OR, members ["user1", "user2", "user3"...])
  append true
end
```

append is used if you want to append the above users to the admin list. leave it out if you want the admin list to be overwritten with the user or users.

a good use of these is to loop over user creation and to add them to a group.


# notifications

notifications are used to notify a resource to take action.

```ruby
notifies :action, "resource[name]", :timer
# timer can be :before, :delayed, :immediately
subscribes :action, "resource[name]", timer
```

:before = notify the resource to take action before the resource I'm embedded inside of
:delayed = execute the resource I'm inside of, and then send the notification
:immediately = send the notification ASAP.

example of notifies:

```ruby
template "/var/www/html/index.html" do
  source "index.html.erb"
  notifies :restart, "service[httpd]", :immediately
end
```

if index.html changed its state, then restart httpd service RIGHT AWAY.

example of subscribes:

```ruby
service "httpd" do
  action [:enable, :start]
  subscribes :restart, "template[/var/www/html/index.html]", :immediately
end
```

this is the same thing, but in a different place. if that template changes, then restart this service RIGHT AWAY.

# debugging, linting, and testing + other bonus content

you can use `chef exec [x]` if [x] does not exist locally, to run it with the chefdk.

`chef exec ruby --help` gives help for ruby stuff. you can run ruby through chef if it does not exist locally

check out `chef shell-init --help` to get info for how to make chef ruby your default ruby, among other things.

if you can't access stuff like `knife`, `chef knife` will work.

docs.chef.io/release/devkit is very helpful for bonus functionality, like foodcritic.

docs.chef.io/ruby.html is a good style guide for chef.

docs.chef.io/debug.html is a good place to learn some debugging tips.

log resource:

```ruby
log "message" do
  message "a message to add to the log"
  level :info
end
```

syntax note: if you want multiple actions to be taken by a resource, put all those actions in an array (i.e. [ :start, :enable ])


# Test Kitchen and unit testing

Test Kitchen is a testing tool used to execute your configured code on one or more platforms in isolation. It's built into the chefdk.

cookbook/.kitchen.yml is where the settings for the Test Kitchen are located. if this doesn't exist, you can generate it with chef.

chef inspec can be used to write tests.

`kitchen list` gives you some relevant information for testing.

in kitchen.yml, there's a bit named suites. Test Kitchen will run the default recipes listed in here.

when you're ready, run `kitchen create` (in the video, it was run from the cookbook directory)

`kitchen create` creates virtual machines for testing. `kitchen list` should tell you if it's created.

run `kitchen converge` to step through the suites section of the kitchen.yml file.

the test recipes are written in a different way than usual recipes - use inspec for this.

`kitchen verify` can be used to see if the tests pass. this can also be used to help debug since the errors give helpful information.

do more research on this - teacher did not go super deep into this area, since it's pretty expansive as a topic

chefspec is good for unit tests. again, teacher didn't go super in-depth on this, so do your own research.

chefspec testing files are put in spec/unit/recipes. generating recipes will automatically put a test version in this directory.

to test one, just do `chef exec rspec spec/unit/recipes/default_spec.rb` for instance.

chefspec uses goofy syntax as well so...Google it, and see inspec for help. :)

coverage reports are nice for seeing how much of your recipe is "touched" by a test.
