class DemoJob < ApplicationJob
  queue_as :default

  def perform
    sleep 2

    Turbo::StreamsChannel.broadcast_replace_to("demo",
      target: "queue-status",
      partial: "demo/queue_status",
      locals: { status: "completed", job_id: provider_job_id })
  end
end
