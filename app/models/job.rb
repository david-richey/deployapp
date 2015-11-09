class Job
  def self.ecs_task(cluster_name, hub)
    client = Aws::CodePipeline::Client.new(
      region: 'us-east-1'
    )

    sleep 60 # roughly a min earlier than pipeline ackn

    no_job = true
    count = 0
    while no_job == true && count < 40 do
      sleep 5
      build_spec = client.poll_for_jobs({
        action_type_id: { # required
          category: "Deploy", # required, accepts Source, Build, Deploy, Test, Invoke
          owner: "Custom", # required, accepts AWS, ThirdParty, Custom
          provider: "ECSTask", # required
          version: "1", # required
        },
        max_batch_size: 10,
      })
      no_job = false if build_spec.jobs.present?
      count += 1
    end
    if no_job
      'No Job'
    else no_job
      job_id = build_spec.jobs.first.id
      nonce = build_spec.jobs.first.nonce

      

      ecs_client = Aws::ECS::Client.new(
        region: 'us-east-1'
      )
      
      container_resp = ecs_client.list_container_instances({
        cluster: cluster_name,
        max_results: 10,
      })

      # Create Task Definition
      task_resp = ecs_client.register_task_definition({
        family: cluster_name+"DockerTask", # required
        container_definitions: [ # required
          {
            name: cluster_name+"DockerRun",
            image: hub,
            cpu: 1,
            memory: 128,
            port_mappings: [
              {
                container_port: 9292,
                host_port: 9292,
                protocol: "tcp", # accepts tcp, udp
              },
            ],
            essential: true,
          },
        ],
      })

      # Acknowledge job
      resp = client.acknowledge_job({
        job_id: job_id, # required
        nonce: nonce, # required
      })

      # Start Task
      resp = ecs_client.run_task({
        cluster: cluster_name,
        task_definition: task_resp.task_definition.task_definition_arn, # required
        # container_instances: [container_resp.container_instance_arns.first.to_s], # required
        started_by: "uid",
      })
      
      pending = 0
      count = 0
      while pending > 0 || count > 5 do
        sleep 5
        clusters = ecs_client.describe_clusters({
          clusters: [cluster_name],
        })
        pending = clusters.pending_tasks_count.to_i
        running = clusters.running_tasks_count
        count += 1
      end

      sleep 5
      clusters = ecs_client.describe_clusters({
        clusters: [cluster_name],
      })
      running = clusters.running_tasks_count

      raise unless running > 0

      # Success or failure
      resp = client.put_job_success_result({
        job_id: job_id, # required
        execution_details: {
          summary: "Completed",
          external_execution_id: "1234",
          percent_complete: 1,
        }
      })

      'Task Sent'

    end
  rescue => e
    Rails.logger.info{"Job Failed"+ e.to_s}
    if job_id
      resp = client.put_job_failure_result({
        job_id: job_id, # required
        failure_details: { # required
          type: "JobFailed", # required, accepts JobFailed, ConfigurationError, PermissionError, RevisionOutOfSync, RevisionUnavailable, SystemUnavailable
          message: e.to_s, # required
        },
      })
    end
  end
end