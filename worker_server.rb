require './job.rb'
require 'thread'

class WorkerServer
  DEFAULT_WORKERS_COUNT = 10

  def initialize(workers_count = DEFAULT_WORKERS_COUNT)
    $jobs ||= Queue.new
    @workers_count = workers_count
    @stopped = false
  end

  def start
    workers = workers_count.times.map do
      Thread.new do
        begin
          while !stopped && job = $jobs.pop(false)
            result = job.perform
            puts("Finished computing job #{job.class_name} - Result: #{result}") if result
            puts("Error executing job #{job.class_name} - Result: #{job.error}") unless result
          end
        rescue => ex
          puts "Job Failed: #{ex.message}"
          # TODO. retry
        end
      end
    end
  end

  def stop
    @stopped = true
  end

  private

  attr_reader :workers_count, :stopped
end
