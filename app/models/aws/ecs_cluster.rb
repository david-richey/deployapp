module Aws
  class EcsCluster
    def initialize(region)
      @client = Aws::ECS::Client.new(
        region: region
      )
    end

    def create(cluster_name)
      @client.create_cluster({
        cluster_name: cluster_name,
      })
    end

    def destroy(cloud_id)
      @cloud = Cloud.find(cloud_id)
      hub = @cloud.ecs_cluster.hub
      cluster_name = @cloud.ecs_cluster.name
      # ECS Cluster
      @client = Aws::ECS::Client.new(
        region: 'us-east-1'
      )
      container_resp = @client.list_container_instances({
        cluster: cluster_name,
        max_results: 10,
      })
      if container_resp.container_instance_arns.count > 0
        container_resp.container_instance_arns.each do |arn|
          @client.deregister_container_instance({
            cluster: cluster_name,
            container_instance: arn, # required
            force: true,
          })
        end
      end
      task_def_resp=@client.list_task_definitions({
        family_prefix: cluster_name+"DockerTask",
        status: "ACTIVE", # accepts ACTIVE, INACTIVE
        sort: "ASC", # accepts ASC, DESC
        max_results: 10,
      })
      if task_def_resp.task_definition_arns.count > 0
        task_def_resp.task_definition_arns.each do |task|
          @client.deregister_task_definition({
            task_definition: task, # required
          })
        end
      end
      
      @client.delete_cluster({
        cluster: cluster_name, # required
      })
      @cloud.ecs_cluster.destroy
    end
  end
end