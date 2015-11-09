class HooksController < ApplicationController
  protect_from_forgery with: :null_session,
      if: Proc.new { |c| c.request.format =~ %r{application/json} }
  def payload
    hub = params['repository']['repo_name']
    cluster_name = EcsCluster.where(hub:hub).first.name
    JobsWorker.perform_in(1.minute, cluster_name, hub, false)
    Rails.logger.info { "Job Queued 1 Minutes" }
    render json: { status: 200 }
  end
  def github
    Rails.logger.info { "Received GitHub Hook" }
    render json: { status: 200 }
  end
end
