require './queue_adapter.rb'
require 'thread'

class ScheduledWorkerServer
  attr_reader :stopped

  def start
    @stopped = false
    @worker = launch_worker_thread
  end

  def stop
    @stopped = true
    @worker.join
    true
  end

  def log(message)
    print("#{message}\n")
  end

  private

  attr_reader :worker

  def launch_worker_thread
    Thread.new do
      begin
        while (job = QueueAdapter.next_scheduled_job) || !stopped
          (sleep(0.5) && next) unless job
          execute_job(job)
        end
      rescue ThreadError
      rescue => ex
        log("SCHEDULED Job Failed: #{ex.class}: #{ex.message}")
        # TODO. enqueue for retry
      end
    end
  end

  def execute_job(job)
    result = job.perform
    log("Finished computing SCHEDULED job #{job.class_name} - Result: #{result}") if result
    log("Error executing SCHEDULED job #{job.class_name} - Result: #{job.error}") unless result
  end
end
