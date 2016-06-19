server 'tools.hosts.dmz',
  roles: %w{web app},
  ssh_options: {
    user: 'askobara', # overrides user setting above
    keys: [File.join(ENV["HOME"], ".ssh", "id_rsa")],
    forward_agent: true,
    auth_methods: %w(publickey)
  }
