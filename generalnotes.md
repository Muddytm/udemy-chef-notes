# IMPORTANT: most chef and chef-client command line stuff is implied to be run as root. Use sudo, or log in as root.

# general

sudo chef-client --local-mode setup.rb (for instance) just runs the code for that machine.

`chef generate` can be used to generate cookbooks, recipes, etc. Type `chef generate` for a list.

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

# ohai

literally just running `ohai` gets you a BUNCH of system information. It's all in a JSON too.

you can also run stuff like `ohai memory` or `ohai cpu/0/mhz`, which also returns info in JSON.

this is the equivalent of puppet facts! :)

example of using ohai node variables in recipes/setup.rb!

also see server.rb in the apache cookbook for another example.
