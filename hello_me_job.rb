class HelloMeJob
  def perform(first_name, last_name)
    "Hello World #{first_name} #{last_name}"
  end
end
