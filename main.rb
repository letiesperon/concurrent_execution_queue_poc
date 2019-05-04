require './worker_server.rb'
require './scheduled_worker_server.rb'
require './clients_listener.rb'
require './hello_world_job.rb'
require './hello_me_job.rb'
require 'thread'
require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'

  # debugging
  gem 'pry', '~> 0.10.3'
  gem 'pry-coolline', '~> 0.2.5'

  # testing
  gem 'rspec', '~> 3.5'
end

ADDRESS = 'localhost'
PORT = 2000

WorkerServer.new.start
ScheduledWorkerServer.new.start
ClientsListener.new(ADDRESS, PORT).start
