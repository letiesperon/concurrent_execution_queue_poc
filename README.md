# Ruby Concurrent Execution Queue

## Intention

### Goal

We want to build an execution queue that takes different commands from multiple clients (concurrently) and execute them one by one according to the command type. It needs to accept 3 types of commands:
1. Execute the job in a synchronous way and return the result (this job skips the queue).
2. Enqueue a job and return its unique identifier.
3. Enqueue a job in at least x seconds from now and return its unique identifier.

The server has to print the result of each job in the server log.

### Task

Implement a multithreaded server that accepts multiple TCP connections. Clients can connect to the server and enqueue different kinds of jobs (defined in the server) that will run, according to the command used, in a synchronous or asynchronous way following a first come- first served criteria.

### Constraints

* There has to be at least 2 job types.
* No Ruby gems allowed except RSpec.
* We recommend using Telnet to connect to the server.
* Unit Tests for all classes (RSpec).
* Add a Readme file documenting the features and how to use them.

### Example client interface

```
perform_now JobClass job_params
perform_later JobClass job_params
perform_in seconds_from_now JobClass job_params
```

---

## Usage

1. Download the folder, open a terminal and cd to the folder.
2. Run `ruby main.rb` to start the threads. This starts:
  a. A listener for TCP connections that listens at `localhost:2000`.
  b. 2 workers for asycn jobs
  c. 1 worker for scheduled async jobs
3. From any other terminal, install telnet and run `telnet localhost 2000`.
4. In the telnet terminal input `perform_now`, `perform_later` or `perform_in` commands and for the latter two see the result in the server terminal.

---

## Example Usage

**Telnet console input/output:**

```
Letis-MacBook-Pro:Server leti$ telnet localhost 2000
Trying ::1...
Connected to localhost.
Escape character is '^]'.
Hey there! Welcome :)
perform_now InvalidJob
That job class is not defined!
perform_now HelloWorldJob invalid_param
The job arguments are not correct :(
perform_now HelloWorldJob
Hello World
invalid_command
Sorry, that is not a valid command.
perform_now HelloMeJob
The job arguments are not correct :(
perform_now HelloMeJob leti esperon
Hello World leti esperon
perform_later InvalidJob
621dbfe9c0
perform_later HelloWorldJob
1fb6fe7b57
perform_later HelloMeJob leti esperon
f752c52fcc
perform_in 10 HelloWorldJob
25ed531e17
perform_in 2 HelloMeJob leti esperon
66672da45f
perform_in 1 InvalidJob
632b106483
perform_in 1 HelloMeJob missing_param
a70283beb7
```

**Server output:**

```
Connected a client.
Error executing ENQUEUED job InvalidJob - Result: That job class is not defined!
Finished computing ENQUEUED job HelloWorldJob - Result: Hello World
Finished computing ENQUEUED job HelloMeJob - Result: Hello World leti esperon
Finished computing SCHEDULED job HelloMeJob - Result: Hello World leti esperon
Finished computing SCHEDULED job HelloWorldJob - Result: Hello World
Error executing SCHEDULED job InvalidJob - Result: That job class is not defined!
Error executing SCHEDULED job HelloMeJob - Result: The job arguments are not correct :(
```

---

## Considerations
* When the client inputs `perform_now` command, the job is not stored anywhere but performed right away in the same client server thread.
* Scheduled jobs are handled in a different queue to be able to have them ordered by time to be performed. In this way, we favour a quick lecture of the next job to run, since this is going to be done all the time, sacrificing the execution time of the enquue job action.
* There is a special worker thread in charge of scheduled jobs, but there could be more than one like there is for jobs enqueued to be ran asap.
* Workers threads sleep 0.5 between the times they queried an empty queue to maintain a low CPU consumption.
* Client listener does not sleep since `socket.accept` is a blocking method.
* `print` with `\n` was used instead of `puts` since it is thread safe.

---

## Future Improvements

1. **Make the scheduled jobs queue implementation thread safe.** Right now it's an array to allow sorting and it's not using locks to read and write so race condition between worker threads might be possible.
It does not happend with the non scheduled jobs queue because the ruby `Queue` class is already thread safe. There are thread safe implementations of arrays on `concurrent-ruby` gem but I was not allowed to use it.
2. **Make the scheduled queue implementation more performant.** Since my algorithm sorts the queue by perform_at time in each insert to promote fast reading in the worker jobs, we could have used some other structure optimized for this.
3. **Implement the queues in other way than global variables.** The queue is encapsulated on `QueueAdapter` class so changing the queue implementation should not impact on any other part of the code, not even on the specs of this class.
4. **Validate job class name and params before enqueuing.** In `perform_in` and `perform_later` actions it is validated that the first param is a valid number and that the job class name is present, but not if the class exists and if the arguments inputted are the correct number.
5. **Improve and centralize logging**. Define all the error messages in the same place. Centralize logging to a common place instead of using `print`.

---

## Running specs

**Specs output:**

Open a terminal in the project root folder and run tests with `rspec` command.

```
Letis-MacBook-Pro:Server leti$ rspec
.............................................................................

Finished in 0.07414 seconds (files took 0.31294 seconds to load)
77 examples, 0 failures
```

---
