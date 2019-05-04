require './job.rb'
require './scheduled_job.rb'
require 'socket'
require 'active_support/time'

class ClientServer
  EXIT_WORD = 'exit'.freeze

  attr_reader :connection, :stopped

  def initialize(connection)
    @connection = connection
    @stopped = false
  end

  def serve_client
    log('Connected a client.')
    connection.puts('Hey there! Welcome :)')
    while !stopped do
      message = connection.gets.chomp
      handle_exit(message) || handle_command(message)
    end
  rescue IOError
    log('Bye')
  end

  def stop
    @stopped = true
  end

  def handle_exit(message)
    return unless message == EXIT_WORD

    @stopped = true
    connection.close
  end

  def handle_command(message)
    command_parts = message.split(' ')
    command_name = command_parts.shift
    result = send(command_name, command_parts)
    connection.puts(result)
  rescue NoMethodError
    connection.puts("Sorry, that is not a valid command.")
  rescue ArgumentError
    connection.puts("Mmm.. are you sure you sent the right arguments?")
  rescue => ex
    connection.puts("Ugh this is awkward: #{ex.message}")
    log("Error: #{ex.message}")
  end

  private

  def perform_now(command_parts)
    class_name = command_parts.shift
    job = Job.new(class_name, command_parts)

    job.perform || job.error
  end

  def perform_later(command_parts)
    class_name = command_parts.shift
    job = Job.new(class_name, command_parts)
    job.enqueue
    job.id
  end

  def perform_in(command_parts)
    perform_in = command_parts.shift
    perform_at = perform_in.to_i.seconds.from_now
    class_name = command_parts.shift
    job = ScheduledJob.new(class_name, perform_at, command_parts)
    job.enqueue
    job.id
  end

  def log(message)
    print("#{message}\n")
  end
end
