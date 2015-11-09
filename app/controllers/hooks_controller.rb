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

# {"push_data"=>
#   {"pushed_at"=>1446750793, "images"=>["imagehash1", "imagehash2", "imagehash3"], "pusher"=>"davidrichey"},
#  "callback_url"=>"https://registry.hub.docker.com/u/davidrichey/baseruby/hook/2hei4ghcaj0jb4i2fc1455af2013iie3i/",
#  "repository"=>
#   {"status"=>"Active",
#    "description"=>"Base ruby 2.2.3",
#    "is_trusted"=>false,
#    "full_description"=>"",
#    "repo_url"=>"https://registry.hub.docker.com/u/davidrichey/baseruby/",
#    "owner"=>"davidrichey",
#    "is_official"=>false,
#    "is_private"=>false,
#    "name"=>"baseruby",
#    "namespace"=>"davidrichey",
#    "star_count"=>0,
#    "comment_count"=>0,
#    "date_created"=>1446475260,
#    "repo_name"=>"davidrichey/baseruby"},
#  "controller"=>"hooks",
#  "action"=>"payload",
#  "hook"=>
#   {"push_data"=>{"pushed_at"=>1446750793, "images"=>["imagehash1", "imagehash2", "imagehash3"], "pusher"=>"davidrichey"},
#    "callback_url"=>"https://registry.hub.docker.com/u/davidrichey/baseruby/hook/2hei4ghcaj0jb4i2fc1455af2013iie3i/",
#    "repository"=>
#     {"status"=>"Active",
#      "description"=>"Base ruby 2.2.3",
#      "is_trusted"=>false,
#      "full_description"=>"",
#      "repo_url"=>"https://registry.hub.docker.com/u/davidrichey/baseruby/",
#      "owner"=>"davidrichey",
#      "is_official"=>false,
#      "is_private"=>false,
#      "name"=>"baseruby",
#      "namespace"=>"davidrichey",
#      "star_count"=>0,
#      "comment_count"=>0,
#      "date_created"=>1446475260,
#      "repo_name"=>"davidrichey/baseruby"}}}