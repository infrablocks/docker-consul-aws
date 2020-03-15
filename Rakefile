require 'rake_docker'
require 'rake_circle_ci'
require 'rake_github'
require 'rake_ssh'
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

RakeSSH.define_key_tasks(
    namespace: :deploy_key,
    path: 'config/secrets/ci/',
    comment: 'maintainers@infrablocks.io'
)

RakeCircleCI.define_project_tasks(
    namespace: :circle_ci,
    project_slug: 'github/infrablocks/docker-consul-aws'
) do |t|
  circle_ci_config =
      YAML.load_file('config/secrets/circle_ci/config.yaml')

  t.api_token = circle_ci_config["circle_ci_api_token"]
  t.environment_variables = {
      ENCRYPTION_PASSPHRASE:
          File.read('config/secrets/ci/encryption.passphrase')
              .chomp
  }
  t.ssh_keys = [
      {
          hostname: "github.com",
          private_key: File.read('config/secrets/ci/ssh.private')
      }
  ]
end

RakeGithub.define_repository_tasks(
    namespace: :github,
    repository: 'infrablocks/docker-consul-aws'
) do |t|
  github_config =
      YAML.load_file('config/secrets/github/config.yaml')

  t.access_token = github_config["github_personal_access_token"]
  t.deploy_keys = [
      {
          title: 'CircleCI',
          public_key: File.read('config/secrets/ci/ssh.public')
      }
  ]
end

namespace :pipeline do
  task :prepare => [
      :'circle_ci:env_vars:ensure',
      :'circle_ci:ssh_keys:ensure',
      :'github:deploy_keys:ensure'
  ]
end

namespace :base_image do
  RakeDocker.define_image_tasks(
      image_name: 'consul-aws'
  ) do |t|
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
end

namespace :agent_image do
  RakeDocker.define_image_tasks(
      image_name: 'consul-agent-aws'
  ) do |t|
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
end

namespace :server_image do
  RakeDocker.define_image_tasks(
      image_name: 'consul-server-aws'
  ) do |t|
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
end

namespace :registrator_image do
  RakeDocker.define_image_tasks(
      image_name: 'registrator-aws'
  ) do |t|
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
