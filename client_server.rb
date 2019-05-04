require './job.rb'
require './scheduled_job.rb'
require 'socket'
require 'active_support/time'

class ClientServer
  EXIT_WORD = 'exit'.freeze
  ALLOWED_COMMANDS = ['perform_now', 'perform_later', 'perform_in'].freeze

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
    log('Client connection finished.')
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
    if ALLOWED_COMMANDS.include?(command_name)
      execute(command_name, command_parts)
    else
      connection.puts("Sorry, that is not a valid command.")
    end
  rescue => ex
    connection.puts("Ugh this is awkward: #{ex.class} #{ex.message}")
    log("Error: #{ex.message}")
  end

  private

  def execute(command_name, command_parts)
    result = send(command_name, command_parts)
    connection.puts(result) if result
  rescue ArgumentError
    connection.puts("Error: The command arguments are not correct")
  end

  def perform_now(command_parts)
    class_name = command_parts.shift
    send_class_name_missing_error and return unless class_name

    job = Job.new(class_name, command_parts)
    job.perform || job.error
  end

  def perform_later(command_parts)
    class_name = command_parts.shift
    send_class_name_missing_error and return unless class_name

    job = Job.new(class_name, command_parts)
    job.enqueue
    job.id
  end

  def perform_in(command_parts)
    perform_in = Integer(command_parts.shift)
    perform_at = perform_in.to_i.seconds.from_now
    class_name = command_parts&.shift
    send_class_name_missing_error and return unless class_name

    job = ScheduledJob.new(class_name, perform_at, command_parts)
    job.enqueue
    job.id
  rescue ArgumentError, TypeError
    connection.puts('Error: First argument of perform_in must be the number of seconds')
  end

  def send_class_name_missing_error
    connection.puts('Error: Job class name required')
    true
  end

  def log(message)
    print("#{message}\n")
  end
end
