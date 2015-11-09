class PagesController < ApplicationController
  def home
    @clouds = Cloud.all
  end

  def poll_jobs
    # poll for my docker
    mydocker = client.poll_for_jobs({
      action_type_id: { # required
        category: "Build", # required, accepts Source, Build, Deploy, Test, Invoke
        owner: "AWS", # required, accepts AWS, ThirdParty, Custom
        provider: "MyDocker", # required
        version: "1", # required
      },
      max_batch_size: 1,
    })
  end

  def instances
    client = Aws::EC2::Client.new(
      region: 'us-east-1'
    )

    @resp = client.describe_instances({
      dry_run: false,
      filters: [
        {
          name: "key-name",
          values: ["davidrichey"],
        },
        {
          name: "instance-state-name",
          values: ["running", "pending"],
        },
      ],
    })
  end
end
