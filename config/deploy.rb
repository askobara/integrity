# config valid only for current version of Capistrano
lock '3.5.0'

set :application, 'integrity'
set :repo_url, 'https://github.com/askobara/integrity.git'

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp
set :branch, 'thisisriver'

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, "~/#{fetch(:application)}"

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
set :linked_files, fetch(:linked_files, []).push('.env', 'local.rb', 'credentials.yaml', 'db/integrity.db')

# Default value for linked_dirs is []
set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle')

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

set :unicorn_pid, '/tmp/unicorn.pid'
set :unicorn_config, 'config/unicorn.rb'
set :unicorn_env, :development

set :bundle_path, -> { shared_path.join('vendor', 'bundle') }

namespace :unicorn do
  desc 'Stop Unicorn'
  task :stop do
    on roles(:app) do
      if test("[ -f #{fetch(:unicorn_pid)} ]")
        execute :kill, capture(:cat, fetch(:unicorn_pid))
      end
    end
  end

  desc 'Start Unicorn'
  task :start do
    on roles(:app) do
      within current_path do
        execute :bundle, "exec unicorn -c #{fetch(:unicorn_config)} --env #{fetch(:unicorn_env)} --daemonize "
      end
    end
  end

  desc 'Reload Unicorn without killing master process'
  task :reload do
    on roles(:app) do
      if test("[ -f #{fetch(:unicorn_pid)} ]")
        execute :kill, '-s USR2', capture(:cat, fetch(:unicorn_pid))
      else
        error 'Unicorn process not running'
      end
    end
  end

  desc 'Restart Unicorn'
  task :restart
  before :restart, :stop
  before :restart, :start
end

before "deploy:updated", "bundler:install"
after "deploy:published", "unicorn:reload"
