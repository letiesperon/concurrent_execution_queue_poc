require 'securerandom'
require './job.rb'
require 'active_support/core_ext/module/delegation'

class ScheduledJob
  attr_reader :perform_at, :job

  delegate :id, :perform, :error, :class_name, :params, to: :job

  def initialize(class_name, perform_at, params = [])
    @job = Job.new(class_name, params)
    @perform_at = perform_at
  end

  def ready_to_run?
    perform_at <= Time.current
  end

  def enqueue
    QueueAdapter.enqueue_scheduled(self)
  end
end
