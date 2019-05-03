require './job.rb'
require 'thread'

class WorkerServer
  DEFAULT_WORKERS_COUNT = 3

  attr_reader :stopped

  def initialize(workers_count = DEFAULT_WORKERS_COUNT)
    $jobs ||= Queue.new
    @workers_count = workers_count
  end

  def start
    @stopped = false
    @workers = workers_count.times.map do
      Thread.new do
        begin
          while !stopped || (job = $jobs.pop(true))
            next unless job

            result = job.perform
            log("Finished computing job #{job.class_name} - Result: #{result}") if result
            log("Error executing job #{job.class_name} - Result: #{job.error}") unless result
          end
        rescue ThreadError
        rescue => ex
          log ex.class
          log "Job Failed: #{ex.message}"
          # TODO. retry
        end
      end
    end
  end

  def stop
    @stopped = true
    workers.map(&:join)
    workers.clear
    true
  end

  def log(message)
    print("#{message}\n")
  end

  private

  attr_reader :workers_count, :workers
end
