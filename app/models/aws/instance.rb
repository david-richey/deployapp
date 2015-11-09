module Aws
  class Instance
    def initialize(region)
      @client = Aws::EC2::Client.new(
        region: region
      )
    end
    def create(key_pair, number_of_instances, cluster_name)
      resp = @client.run_instances({
        dry_run: false,
        image_id: "ami-ddc7b6b7", # required
        min_count: number_of_instances, # required
        max_count: number_of_instances, # required
        key_name: key_pair,
        # security_groups: ["Kafka-Zookeeper"],
        security_group_ids: ["Kafka-Zookeeper"],
        user_data: encode(cluster_name),

        instance_type: "t2.micro", # accepts t1.micro, m1.small, m1.medium, m1.large, m1.xlarge, m3.medium, m3.large, m3.xlarge, m3.2xlarge, m4.large, m4.xlarge, m4.2xlarge, m4.4xlarge, m4.10xlarge, t2.micro, t2.small, t2.medium, t2.large, m2.xlarge, m2.2xlarge, m2.4xlarge, cr1.8xlarge, i2.xlarge, i2.2xlarge, i2.4xlarge, i2.8xlarge, hi1.4xlarge, hs1.8xlarge, c1.medium, c1.xlarge, c3.large, c3.xlarge, c3.2xlarge, c3.4xlarge, c3.8xlarge, c4.large, c4.xlarge, c4.2xlarge, c4.4xlarge, c4.8xlarge, cc1.4xlarge, cc2.8xlarge, g2.2xlarge, cg1.4xlarge, r3.large, r3.xlarge, r3.2xlarge, r3.4xlarge, r3.8xlarge, d2.xlarge, d2.2xlarge, d2.4xlarge, d2.8xlarge
        # placement: {
        #   group_name: cluster_name,
        #   tenancy: "default", # accepts default, dedicated
        # },
        # kernel_id: "String",
        # ramdisk_id: "String",
        # block_device_mappings: [
        #   {
        #     virtual_name: "String",
        #     device_name: "String",
        #     ebs: {
        #       snapshot_id: "String",
        #       volume_size: 1,
        #       delete_on_termination: true,
        #       volume_type: "standard", # accepts standard, io1, gp2
        #       iops: 1,
        #       encrypted: true,
        #     },
        #     no_device: "String",
        #   },
        # ],
        monitoring: {
          enabled: false, # required
        },
        disable_api_termination: false,
        instance_initiated_shutdown_behavior: "terminate", # accepts stop, terminate
        # private_ip_address: "String",
        # client_token: "String",
        # additional_info: "String",
        # network_interfaces: [
        #   {
        #     network_interface_id: "String",
        #     device_index: 1,
        #     subnet_id: "String",
        #     description: "String",
        #     private_ip_address: "String",
        #     groups: ["String"],
        #     delete_on_termination: true,
        #     private_ip_addresses: [
        #       {
        #         private_ip_address: "String", # required
        #         primary: true,
        #       },
        #     ],
        #     secondary_private_ip_address_count: 1,
        #     associate_public_ip_address: true,
        #   },
        # ],
        iam_instance_profile: {
          name: "ecsInstanceRole",
        },
        ebs_optimized: false,
      })

      resp.instances.map{ |i| i.instance_id}.join(', ')
    end

    def destroy(cloud_id)
      @cloud = Cloud.find(cloud_id)
      # EC2 Instance
      ids = @cloud.instance.ids.split(', ')
      # EC2 Instance
      
      @client.terminate_instances({
        dry_run: false,
        instance_ids: ids, # required
      })
      @cloud.instance.destroy
    end

    def encode(cluster_name)
      text = "#!/bin/bash -ex\n
              echo ECS_CLUSTER="+cluster_name+" >> /etc/ecs/ecs.config\n
              yum install -y docker\n
              service docker start\n
              usermod -a -G docker ec2-user\n
              yum update -y aws-cfn-bootstrap\n
              yum install -y ruby\n
              yum install -y aws-cli\n
              cd /home/ec2-user\n
              aws s3 cp 's3://aws-codedeploy-us-east-1/latest/codedeploy-agent.noarch.rpm' .\n
              chmod +x ./install\n
              ./install auto\n"

      Base64.encode64(text)
    end
  end
end