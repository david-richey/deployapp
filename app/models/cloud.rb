class Cloud < ActiveRecord::Base
  has_one :cloud_formation_stack
  has_one :code_deploy
  has_one :code_pipeline
  has_one :ecs_cluster
  has_one :instance
end
