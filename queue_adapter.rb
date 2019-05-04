module QueueAdapter
  def self.enqueue(job)
    jobs.push(job)
  end

  def self.enqueue_scheduled(scheduled_job)
    scheduled_jobs << scheduled_job
    scheduled_jobs.sort_by! { |job| job.perform_at }
  end

  def self.next_job
    jobs.pop(true)
  rescue
    nil
  end

  def self.next_scheduled_job
    next_job = scheduled_jobs.first
    if next_job.ready_to_run?
      scheduled_jobs.shift
    end
  rescue
    nil
  end

  def self.clear_queues
    jobs.clear
    scheduled_jobs.clear
  end

  def self.jobs
    $jobs ||= Queue.new
  end

  def self.scheduled_jobs
    $scheduled_jobs ||= []
  end
end
