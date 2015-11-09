module Aws
  class Pipeline
    def initialize(region)
      @client = Aws::CodePipeline::Client.new(
        region: region
      )
    end

    def create(pipeline_name, github_owner, repo, hub, cluster_name)
      @client.create_pipeline({
        pipeline: { # required
          name: pipeline_name, # required
          role_arn: "arn:aws:iam::360684457758:role/AWS-CodePipeline-Service", # required
          artifact_store: { # required
            type: "S3", # required, accepts S3
            location: "codepipeline-us-east-1-683920855633", # required
          },
          stages: [ # required
            {
              name: "GitHubSource", # required
              actions: [ # required
                {
                  name: "Source", # required
                  action_type_id: { # required
                    category: "Source", # required, accepts Source, Build, Deploy, Test, Invoke
                    owner: "ThirdParty", # required, accepts AWS, ThirdParty, Custom
                    provider: "GitHub", # required
                    version: "1", # required
                  },
                  run_order: 1,
                  configuration: {
                    "Branch" => "master",
                    "OAuthToken" => ENV["OAUTHTOKEN"],
                    "Owner" => github_owner,
                    "Repo" => repo
                  },
                  output_artifacts: [
                    {
                      name: "MyApp", # required
                    },
                  ],
                },
              ],
            },
            {
              name: "DockerBuild", # required
              actions: [ # required
                {
                  name: "DockerDeploy", # required
                  action_type_id: { # required
                    category: "Deploy", # required, accepts Source, Build, Deploy, Test, Invoke
                    owner: "AWS", # required, accepts AWS, ThirdParty, Custom
                    provider: "CodeDeploy", # required
                    version: "1", # required
                  },
                  run_order: 2,
                  configuration: {
                    "ApplicationName"=>"Demo",
                    "DeploymentGroupName"=>"Demo"
                  },
                  input_artifacts: [
                    {
                      name: "MyApp", # required
                    },
                  ],
                },
              ],
            },
            {
              name: "ECSStartTask", # required
              actions: [ # required
                {
                  name: "ECSTask", # required
                  action_type_id: { # required
                    category: "Deploy", # required, accepts Source, Build, Deploy, Test, Invoke
                    owner: "Custom", # required, accepts AWS, ThirdParty, Custom
                    provider: "ECSTask", # required
                    version: "1", # required
                  },
                  run_order: 3,
                  configuration: {
                    "ECSTask"=>"Start ECS Task (docker run)",
                  },
                },
              ],
            },
          ],
          version: 1,
        },
      })
    end

    def destroy(cloud_id)
      @cloud = Cloud.find(cloud_id)
      # CodePipeline
      pipeline_name = @cloud.code_pipeline.name
      @client = Aws::CodePipeline::Client.new(
        region: 'us-east-1'
      )
      @client.delete_pipeline({
        name: pipeline_name, # required
      })
      @cloud.code_pipeline.destroy
    end
  end
end