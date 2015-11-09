class JobsWorker
  include Sidekiq::Worker
  sidekiq_options retry: 2

  def perform(cluster_name, hub, fail_it)
    logger.info{ "Job kicked off #{cluster_name} - #{hub}"}
    client = Aws::CodePipeline::Client.new(
      region: 'us-east-1'
    )

    no_job = true
    count = 0
    while no_job == true && count < 50 do
      sleep 3
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
      logger.info{ "Found AWS Job - #{job_id}"}

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
      raise "Told_to_fail" if fail_it

      stop_task_resp = ecs_client.list_tasks({
        cluster: cluster_name,
        family: cluster_name+"DockerTask",
        max_results: 10,
        desired_status: "RUNNING", # accepts RUNNING, PENDING, STOPPED
      })

      if stop_task_resp.task_arns.count > 0
        stop_task_resp.task_arns.each do |task|
          ecs_client.stop_task({
            cluster: cluster_name,
            task: task, # required
          })
        end
      end

      # Start Task
      containers = container_resp.container_instance_arns.map{ |i| i.to_s}
      resp = ecs_client.run_task({
        cluster: cluster_name,
        task_definition: task_resp.task_definition.task_definition_arn, # required
        # container_instances: containers, # required
        started_by: "uid",
      })

      pending = 0
      count = 0
      sleep 5
      while pending > 0 || count > 12 do
        sleep 5
        clusters_resp = ecs_client.describe_clusters({
          clusters: [cluster_name],
        })
        pending = clusters_resp.clusters.first.pending_tasks_count.to_i
        running = clusters_resp.clusters.first.running_tasks_count
        logger.info{ "AWS Job Pending #{job_id} " } if pending > 0
        count += 1
      end
      logger.info{ "AWS Job Done #{job_id}" }
      sleep 25
      clusters_resp = ecs_client.describe_clusters({
        clusters: [cluster_name],
      })
      running = clusters_resp.clusters.first.running_tasks_count

      raise "No_running_job_error" unless running > 0

      logger.info{ "AWS Job Running #{job_id}" }
      # Success or failure
      resp = client.put_job_success_result({
        job_id: job_id, # required
        execution_details: {
          summary: "Completed",
          external_execution_id: "1234",
          percent_complete: 1,
        }
      })
      logger.info{ "AWS Job success - #{job_id}"}

      'Task Sent'
    end
  rescue => e
    logger.info{"Job Failed "+ e.to_s}
    if job_id
      resp = client.put_job_failure_result({
        job_id: job_id, # required
        failure_details: { # required
          type: "JobFailed", # required, accepts JobFailed, ConfigurationError, PermissionError, RevisionOutOfSync, RevisionUnavailable, SystemUnavailable
          message: e.to_s, # required
        },
      })
      logger.info{ "AWS Job failure sent - #{job_id}"}
    end
  end
end