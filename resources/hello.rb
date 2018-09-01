# Writes "Hello, world!" to /hello.txt

file "/hello.txt" do
  content "Hello, world!"
  # action :create
end

# file = type of resource
# "/hello.txt" = name of resource, is usually path to resource as well
# content = properties that are examined by chef
# if no ACTION is listed, the default action is applied

# Further notes: chef-client --local-mode does stuff on the local machine using chef, disconnected from the chef server.
# This is my first chef recipe, woooooo?
