class DemoController < ApplicationController
  def index
    @stats = {
      cache_entries: SolidCache::Entry.count,
      queue_jobs: SolidQueue::Job.count,
      queue_processes: SolidQueue::Process.count,
      cable_messages: SolidCable::Message.count
    }
  end

  def cache_write
    @value = "Hello from Solid Cache @ #{Time.current.strftime('%H:%M:%S')}"
    Rails.cache.write("demo:greeting", @value, expires_in: 30.seconds)
    @hit = true
    @action = "write"
    render turbo_stream: turbo_stream.replace("cache-status", partial: "demo/cache_status")
  end

  def cache_read
    @value = Rails.cache.read("demo:greeting")
    @hit = @value.present?
    @action = "read"
    render turbo_stream: turbo_stream.replace("cache-status", partial: "demo/cache_status")
  end

  def enqueue_job
    job = DemoJob.perform_later
    render turbo_stream: turbo_stream.replace("queue-status",
      partial: "demo/queue_status",
      locals: { status: "enqueued", job_id: job.provider_job_id })
  end

  def broadcast
    message = "Broadcast received @ #{Time.current.strftime('%H:%M:%S.%L')}"
    Turbo::StreamsChannel.broadcast_replace_to("demo",
      target: "cable-status",
      partial: "demo/cable_status",
      locals: { message: message })
    head :ok
  end

  def stats
    render turbo_stream: turbo_stream.replace("db-stats", partial: "demo/stats", locals: {
      stats: {
        cache_entries: SolidCache::Entry.count,
        queue_jobs: SolidQueue::Job.count,
        queue_processes: SolidQueue::Process.count,
        cable_messages: SolidCable::Message.count
      }
    })
  end
end
