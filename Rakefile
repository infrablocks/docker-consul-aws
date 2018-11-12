require 'rake_docker'
require 'rake_terraform'
require 'yaml'
require 'git'
require 'semantic'

require_relative 'lib/version'

Docker.options = {
    read_timeout: 300
}

def repo
  Git.open('.')
end

def latest_tag
  repo.tags.map do |tag|
    Semantic::Version.new(tag.name)
  end.max
end

namespace :base_image do
  RakeDocker.define_image_tasks do |t|
    t.image_name = 'consul-aws'
    t.work_directory = 'build/images'

    t.copy_spec = [
        "src/consul-aws/Dockerfile",
        "src/consul-aws/docker-entrypoint.sh",
    ]

    t.repository_name = 'consul-aws'
    t.repository_url = 'infrablocks/consul-aws'

    t.credentials = YAML.load_file(
        "config/secrets/dockerhub/credentials.yaml")

    t.tags = [latest_tag.to_s, 'latest']
  end

  desc 'Build and push image'
  task :publish do
    Rake::Task['base_image:clean'].invoke
    Rake::Task['base_image:build'].invoke
    Rake::Task['base_image:tag'].invoke
    Rake::Task['base_image:push'].invoke
  end
end

namespace :agent_image do
  RakeDocker.define_image_tasks do |t|
    t.image_name = 'consul-agent-aws'
    t.work_directory = 'build/images'

    t.copy_spec = [
        "src/consul-agent-aws/Dockerfile",
        "src/consul-agent-aws/docker-entrypoint.sh",
    ]

    t.repository_name = 'consul-agent-aws'
    t.repository_url = 'infrablocks/consul-agent-aws'

    t.credentials = YAML.load_file(
        "config/secrets/dockerhub/credentials.yaml")

    t.build_args = {
        BASE_IMAGE_VERSION: latest_tag.to_s
    }

    t.tags = [latest_tag.to_s, 'latest']
  end

  desc 'Build and push image'
  task :publish do
    Rake::Task['agent_image:clean'].invoke
    Rake::Task['agent_image:build'].invoke
    Rake::Task['agent_image:tag'].invoke
    Rake::Task['agent_image:push'].invoke
  end
end

namespace :server_image do
  RakeDocker.define_image_tasks do |t|
    t.image_name = 'consul-server-aws'
    t.work_directory = 'build/images'

    t.copy_spec = [
        "src/consul-server-aws/Dockerfile",
        "src/consul-server-aws/docker-entrypoint.sh",
    ]

    t.repository_name = 'consul-server-aws'
    t.repository_url = 'infrablocks/consul-server-aws'

    t.credentials = YAML.load_file(
        "config/secrets/dockerhub/credentials.yaml")

    t.build_args = {
        BASE_IMAGE_VERSION: latest_tag.to_s
    }

    t.tags = [latest_tag.to_s, 'latest']
  end

  desc 'Build and push image'
  task :publish do
    Rake::Task['server_image:clean'].invoke
    Rake::Task['server_image:build'].invoke
    Rake::Task['server_image:tag'].invoke
    Rake::Task['server_image:push'].invoke
  end
end

namespace :registrator_image do
  RakeDocker.define_image_tasks do |t|
    t.image_name = 'registrator-aws'
    t.work_directory = 'build/images'

    t.copy_spec = [
        "src/registrator-aws/Dockerfile",
        "src/registrator-aws/docker-entrypoint.sh",
    ]

    t.repository_name = 'registrator-aws'
    t.repository_url = 'infrablocks/registrator-aws'

    t.credentials = YAML.load_file(
        "config/secrets/dockerhub/credentials.yaml")

    t.tags = [latest_tag.to_s, 'latest']
  end

  desc 'Build and push image'
  task :publish do
    Rake::Task['registrator_image:clean'].invoke
    Rake::Task['registrator_image:build'].invoke
    Rake::Task['registrator_image:tag'].invoke
    Rake::Task['registrator_image:push'].invoke
  end
end

namespace :version do
  task :bump, [:type] do |_, args|
    next_tag = latest_tag.send("#{args.type}!")
    repo.add_tag(next_tag.to_s)
    repo.push('origin', 'master', tags: true)
  end

  task :release do
    next_tag = latest_tag.release!
    repo.add_tag(next_tag.to_s)
    repo.push('origin', 'master', tags: true)
  end
end
