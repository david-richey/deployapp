desc 'check for running jobs'
task :check_for_jobs => :environment do 
  JobsWorker.perform_async('RubyAppCluster', 'davidrichey/baseruby', true)
end