class CloudsController < ApplicationController
  before_action :get_cloud, only: [:cloud, :deploy, :destroy]

  def new
    # CodeDeploy
    cd_client = Aws::CodeDeploy::Client.new(
      region: 'us-east-1'
    )
    resp = cd_client.get_deployment_group({
      application_name: 'Demo', # required
      deployment_group_name: 'Demo', # required
    })
    @codedeploy = resp.deployment_group_info
  end

  def cloud
    # CloudFormation
    # cloudformation_name = @cloud.cloud_formation_stack.name
    # Codedeploy
    # deploy_application = @cloud.code_deploy.app_name
    # deploy_group = @cloud.code_deploy.group_name
    if @cloud.code_pipeline.present?
      # CodePipeline
      pipeline_name = @cloud.code_pipeline.name

      # Pipeline Client
      pipeline_client = Aws::CodePipeline::Client.new(
        region: 'us-east-1'
      )

      @resp = pipeline_client.get_pipeline_state({
        name: pipeline_name, # required
      })
    end

    if @cloud.ecs_cluster.present?
      # ECS Cluster
      cluster_name = @cloud.ecs_cluster.name

      # ECS Client
      ecs_client = Aws::ECS::Client.new(
        region: 'us-east-1'
      )

      clusters = ecs_client.describe_clusters({
        clusters: [cluster_name],
      })
      @cluster = clusters.clusters.first
    end

    # EC2 Instance
    if @cloud.instance.present?
      ids = @cloud.instance.ids.split(', ')
      # EC2 Client
      instance_client = Aws::EC2::Client.new(
        region: 'us-east-1'
      )
      resp = instance_client.describe_instances({
        dry_run: false,
        instance_ids: ids,
      })
      @instances = resp.reservations.first.instances
    end


    # CloudFormation
    # cf_client = Aws::CloudFormation::Client.new(
    #   region: 'us-east-1'
    # )
    # resp = cf_client.describe_stacks({
    #   stack_name: cloudformation_name,
    # })
    # @stack = resp.stacks.first

    # # CodeDeploy
    # cd_client = Aws::CodeDeploy::Client.new(
    #   region: 'us-east-1'
    # )
    # resp = cd_client.get_deployment_group({
    #   application_name: deploy_application, # required
    #   deployment_group_name: deploy_group, # required
    # })
    # @codedeploy = resp.deployment_group_info
  end

  def deploy
    pipeline = @cloud.code_pipeline
    client = Aws::CodePipeline::Client.new(
      region: 'us-east-1'
    )
    resp = client.start_pipeline_execution({
      name: pipeline.name, # required
    })
    redirect_to cloud_path(id:@cloud.id)
  end

  def create
    cloud = Cloud.create(name: params[:cloud_name])

    # ECS Cluster
    hub = params[:docker_hub]
    cluster_name = params[:cluster_name]

    # EC2 Instance
    number_of_instances = params[:number_of_instances]
    key_pair = params[:key_pair]

    # CodePipeline
    github_owner = params[:codepipeline_github_owner]
    repo = params[:codepipeline_repo]
    pipeline_name = params[:codepipeline_name]

    # ECS Cluster
    cluster = Aws::EcsCluster.new('us-east-1')
    cluster.create(cluster_name)
    # ecs_cluster(cluster_name)
    EcsCluster.create(name: params[:cluster_name], hub: params[:docker_hub], cloud_id: cloud.id)

    # EC2 Instances
    instance = Aws::Instance.new('us-east-1')
    ids = instance.create(key_pair, number_of_instances, cluster_name)
    # ids = instance(key_pair, number_of_instances, cluster_name)
    Instance.create(ids: ids, cloud_id: cloud.id)

    # CodePipeline
    pipeline = Aws::Pipeline.new('us-east-1')
    pipeline.create(pipeline_name, github_owner, repo, hub, cluster_name)
    # code_pipeline(pipeline_name, github_owner, repo, hub, cluster_name)
    CodePipeline.create(github_owner: params[:codepipeline_github_owner], name: params[:codepipeline_name],
      repo: params[:codepipeline_repo], hub: params[:docker_hub], cloud_id: cloud.id)


    # Cloud Formation
    # CloudFormationStack.create(name: params[:cloudformation_name], cloud_id: cloud.id)
    # stack_name = params[:cloudformation_name]

    # CodeDeploy
    # keyandvalue = params[:codedeploy_key]
    # deploy_config_name = params[:codedeploy_config_name]
    # deploy_application = params[:codedeploy_app_name]
    # deploy_group = params[:codedeploy_group_name]
    # CloudFormation
    # cloud_formation(stack_name, cluster_name)

    # CodeDeploy
    # code_deploy(keyandvalue, deploy_config_name, deploy_application, deploy_group)
    # CodeDeploy.create(config_name: params[:codedeploy_config_name],
    #   app_name: params[:codedeploy_app_name], group_name: params[:codedeploy_group_name],
    #   key: params[:codedeploy_key], value: params[:codedeploy_value], cloud_id: cloud.id)

    redirect_to cloud_path(id:cloud.id)
  end

  # def cloud_formation(stack_name, cluster_name)
  #   # Init cloud formation
  #   client = Aws::CloudFormation::Client.new(
  #     region: 'us-east-1'
  #   )

  #   # Create stack
  #   resp = client.create_stack({
  #     stack_name: stack_name, # required
  #     template_body: my_json(cluster_name),
  #     timeout_in_minutes: 5,
  #     capabilities: ["CAPABILITY_IAM"], # accepts CAPABILITY_IAM
  #     on_failure: "ROLLBACK", # accepts DO_NOTHING, ROLLBACK, DELETE
  #   })
  # end
  # def encode(cluster_name)
  #   text = "#!/bin/bash -ex\n
  #           echo ECS_CLUSTER="+cluster_name+" >> /etc/ecs/ecs.config\n
  #           yum install -y docker\n
  #           service docker start\n
  #           usermod -a -G docker ec2-user\n
  #           yum update -y aws-cfn-bootstrap\n
  #           yum install -y ruby\n
  #           yum install -y aws-cli\n
  #           cd /home/ec2-user\n
  #           aws s3 cp 's3://aws-codedeploy-us-east-1/latest/codedeploy-agent.noarch.rpm' .\n
  #           chmod +x ./install\n
  #           ./install auto\n"

  #   Base64.encode64(text)
  # end
  
  # def code_deploy(keyandvalue, config_name, deploy_application, deploy_group)
  #   client = Aws::CodeDeploy::Client.new(
  #     region: 'us-east-1'
  #   )
  #   # TODO - check for config
  #   # Create Config
  #   # resp = client.create_deployment_config({
  #   #   deployment_config_name: config_name, # required
  #   #   minimum_healthy_hosts: {
  #   #     value: 0,
  #   #     type: "HOST_COUNT", # accepts HOST_COUNT, FLEET_PERCENT
  #   #   },
  #   # })

  #   # TODO - check for application
  #   # # Create Applicaiton
  #   # resp = client.create_application({
  #   #   application_name: deploy_application, # required
  #   # })

  #   # Create Group
  #   resp = client.create_deployment_group({
  #     application_name: deploy_application, # required
  #     deployment_group_name: deploy_group, # required
  #     deployment_config_name: config_name,
  #     ec2_tag_filters: [
  #       {
  #         key: keyandvalue,
  #         value: keyandvalue,
  #         type: "KEY_AND_VALUE", # accepts KEY_ONLY, VALUE_ONLY, KEY_AND_VALUE
  #       },
  #     ],
  #     service_role_arn: "arn:aws:iam::360684457758:role/CodeDeploySampleStack-5iza1yvi-CodeDeployTrustRole-1FJL8II2SHASY", # required
  #   })
  # end

  def destroy
    # Cloud Formation
    # stack_name = @cloud.cloud_formation_stack.name

    # # CodeDeploy
    # keyandvalue = @cloud.code_deploy.key
    # deploy_config_name = @cloud.code_deploy.config_name
    # deploy_application = @cloud.code_deploy.app_name
    # deploy_group = @cloud.code_deploy.group_name

    # ECS Cluster
    if @cloud.ecs_cluster
      cluster = Aws::EcsCluster.new('us-east-1')
      cluster.destroy(@cloud.id)
    end

    if @cloud.instance
      instance = Aws::Instance.new('us-east-1')
      instance.destroy(@cloud.id)
    end

    

    if @cloud.code_pipeline
      pipeline = Aws::Pipeline.new('us-east-1')
      pipeline.destroy(@cloud.id)
    end


    # # CodeDeploy
    # client = Aws::CodeDeploy::Client.new(
    #   region: 'us-east-1'
    # )
    # client.delete_deployment_group({
    #   application_name: deploy_application, # required
    #   deployment_group_name: deploy_group, # required
    # })

    # Delete Application
    # resp = client.delete_deployment_group({
    #   application_name: "DemoApp", # required
    #   deployment_group_name: "MyNewGroup", # required
    # })

    # Delete Config
    # resp = client.delete_deployment_config({
    #   deployment_config_name: config_name, # required
    # })

    # @cloud.code_deploy.destroy

    # # CloudFormation
    # cloud_formation(stack_name, cluster_name)
    # client = Aws::CloudFormation::Client.new(
    #   region: 'us-east-1'
    # )
    # resp = client.delete_stack({
    #   stack_name: stack_name, # required
    # })
    # @cloud.cloud_formation_stack.destroy

    @cloud.destroy

    redirect_to root_path, notice: 'Destroyed'
  end

  private

  def get_cloud
    @cloud = Cloud.find(params[:id])
  end
end