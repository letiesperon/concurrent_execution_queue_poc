require './queue_adapter.rb'
require 'thread'

class WorkerServer
  DEFAULT_WORKERS_COUNT = 3

  attr_reader :stopped

  def initialize(workers_count = DEFAULT_WORKERS_COUNT)
    @workers_count = workers_count
  end

  def start
    @stopped = false
    @workers = workers_count.times.map do
      launch_worker_thread
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

  def launch_worker_thread
    Thread.new do
      begin
        while (job = QueueAdapter.next_job) || !stopped
          (sleep(0.5) && next) unless job
          execute_job(job)
        end
      rescue ThreadError
      rescue => ex
        log("ENQUEUED Job Failed: #{ex.class}: #{ex.message}")
        # TODO. retry
      end
    end
  end

  def execute_job(job)
    result = job.perform
    log("Finished computing ENQUEUED job #{job.class_name} - Result: #{result}") if result
    log("Error executing ENQUEUED job #{job.class_name} - Result: #{job.error}") unless result
  end
end
