# define paths and filenames
app_dir = File.expand_path("../..", __FILE__)
pid_file = '/tmp/unicorn.pid'

timeout 30
listen '127.0.0.1:9292'
worker_processes 2 # increase or decrease

pid pid_file
stderr_path "#{app_dir}/log/unicorn.stderr.log"
stdout_path "#{app_dir}/log/unicorn.stdout.log"
working_directory app_dir

# make forks faster
preload_app true

# make sure that Bundler finds the Gemfile
before_exec do |server|
  ENV['BUNDLE_GEMFILE'] = File.expand_path('../Gemfile', File.dirname(__FILE__))
end

before_fork do |server, worker|
  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.connection.disconnect!

  # zero downtime deploy magic:
  # if unicorn is already running, ask it to start a new process and quit.
  old_pid = "#{server.config[:pid]}.oldbin"
  if File.exists?(old_pid) && server.pid != old_pid
    begin
      Process.kill("QUIT", File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # someone else did our job for us
    end
  end
end

after_fork do |server, worker|
  # re-establish activerecord connections.
  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.establish_connection
end
