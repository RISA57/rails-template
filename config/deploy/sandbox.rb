set :branch, :develop

server '', user: 'deployer', roles: %w(web app db)

set :ssh_options, {
  forward_agent: true
}
