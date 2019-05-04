require 'securerandom'
require './queue_adapter.rb'

class Job
  attr_reader :id, :error, :class_name, :params

  def initialize(class_name, params = [])
    @id = SecureRandom.hex(5)
    @class_name = class_name
    @params = params
  end

  def perform
    Object.const_get(class_name).new.perform(*params)
  rescue NameError
    @error = "That job class is not defined!"
    nil
  rescue ArgumentError
    @error = "The job arguments are not correct :("
    nil
  end

  def enqueue
    QueueAdapter.enqueue(self)
  end
end
