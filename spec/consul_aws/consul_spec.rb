# frozen_string_literal: true

require 'spec_helper'

describe 'consul-aws consul' do
  metadata_service_url = 'http://metadata:1338'
  s3_endpoint_url = 'http://s3:4566'
  s3_bucket_region = 'us-east-1'
  s3_bucket_path = 's3://bucket'
  s3_env_file_object_path = 's3://bucket/env-file.env'

  environment = {
    'AWS_METADATA_SERVICE_URL' => metadata_service_url,
    'AWS_ACCESS_KEY_ID' => '...',
    'AWS_SECRET_ACCESS_KEY' => '...',
    'AWS_S3_ENDPOINT_URL' => s3_endpoint_url,
    'AWS_S3_BUCKET_REGION' => s3_bucket_region,
    'AWS_S3_ENV_FILE_OBJECT_PATH' => s3_env_file_object_path
  }
  image = 'consul-aws:latest'
  extra = {
    'Entrypoint' => '/bin/sh',
    'HostConfig' => {
      'NetworkMode' => 'docker_consul_aws_test_default'
    }
  }

  before(:all) do
    set :backend, :docker
    set :env, environment
    set :docker_image, image
    set :docker_container_create_options, extra
  end

  describe 'command' do
    after(:all, &:reset_docker_backend)

    it 'includes the consul command' do
      expect(command('/opt/consul/bin/consul --version').stdout)
        .to match(/1.8.10/)
    end
  end

  describe 'entrypoint' do
    describe 'with agent subcommand' do
      before(:all) do
        create_env_file(
          endpoint_url: s3_endpoint_url,
          region: s3_bucket_region,
          bucket_path: s3_bucket_path,
          object_path: s3_env_file_object_path
        )

        execute_command('chown -R root:root /opt/consul/data')
        execute_command('chown -R root:root /opt/consul/config')

        execute_docker_entrypoint(
          arguments: %w[agent -server],
          started_indicator: 'Started .* server'
        )
      end

      after(:all, &:reset_docker_backend)

      it 'runs a consul agent' do
        expect(process('/opt/consul/bin/consul')).to be_running
      end

      it 'uses consul as owning user for /opt/consul/data' do
        expect(file('/opt/consul/data')).to(be_owned_by('consul'))
      end

      it 'uses consul as owning group for /opt/consul/data' do
        expect(file('/opt/consul/data')).to(be_grouped_into('consul'))
      end

      it 'uses consul as the owning user for /opt/consul/config' do
        expect(file('/opt/consul/config')).to(be_owned_by('consul'))
      end

      it 'uses consul as the owning group for /opt/consul/config' do
        expect(file('/opt/consul/config')).to(be_grouped_into('consul'))
      end

      it 'does not set any capabilities on the consul binary' do
        capabilities = command('getcap /opt/consul/bin/consul').stdout

        expect(capabilities)
          .not_to(match(/cap_net_bind_service/))
      end

      it 'runs with the consul user' do
        expect(process('/opt/consul/bin/consul').user)
          .to(eq('consul'))
      end

      it 'runs with the consul group' do
        expect(process('/opt/consul/bin/consul').group)
          .to(eq('consul'))
      end

      it 'uses the correct data directory' do
        expect(process('/opt/consul/bin/consul').args)
          .to(match(%r{-data-dir=/opt/consul/data}))
      end

      it 'uses the correct config directory' do
        expect(process('/opt/consul/bin/consul').args)
          .to(match(%r{-config-dir=/opt/consul/config}))
      end

      it 'uses json logging' do
        expect(process('/opt/consul/bin/consul').args)
          .to(match(/-log-json/))
      end

      it 'does not include the bind option' do
        expect(process('/opt/consul/bin/consul').args)
          .not_to(match(/-bind/))
      end

      it 'does not include the client option' do
        expect(process('/opt/consul/bin/consul').args)
          .not_to(match(/-client/))
      end

      it 'does not enable the UI' do
        expect(process('/opt/consul/bin/consul').args)
          .not_to(match(/-ui/))
      end

      it 'does not include any retry join options' do
        expect(process('/opt/consul/bin/consul').args)
          .not_to(match(/-retry-join/))
      end

      it 'does not include the bootstrap expect option' do
        expect(process('/opt/consul/bin/consul').args)
          .not_to(match(/-bootstrap-expect/))
      end
    end

    describe 'with bind interface provided' do
      before(:all) do
        create_env_file(
          endpoint_url: s3_endpoint_url,
          region: s3_bucket_region,
          bucket_path: s3_bucket_path,
          object_path: s3_env_file_object_path,
          env: {
            'CONSUL_BIND_INTERFACE' => 'eth0'
          }
        )

        execute_docker_entrypoint(
          arguments: ['agent', '-server'],
          started_indicator: 'Started .* server'
        )
      end

      after(:all, &:reset_docker_backend)

      it 'includes the bind option with the correct IP address' do
        ip_address = command(
          'ip -o -4 addr list eth0 ' \
          '| head -n1 ' \
          "| awk '{print $4}' " \
          '| cut -d/ -f1'
        )
                     .stdout
                     .strip

        expect(process('/opt/consul/bin/consul').args)
          .to(match(/-bind=#{Regexp.escape(ip_address)}/))
      end
    end

    describe 'with client interface provided' do
      before(:all) do
        create_env_file(
          endpoint_url: s3_endpoint_url,
          region: s3_bucket_region,
          bucket_path: s3_bucket_path,
          object_path: s3_env_file_object_path,
          env: {
            'CONSUL_CLIENT_INTERFACE' => 'eth0'
          }
        )

        execute_docker_entrypoint(
          arguments: ['agent', '-server'],
          started_indicator: 'Started .* server'
        )
      end

      after(:all, &:reset_docker_backend)

      it 'includes the client option with the correct IP address' do
        ip_address = command(
          'ip -o -4 addr list eth0 ' \
          '| head -n1 ' \
          "| awk '{print $4}' " \
          '| cut -d/ -f1'
        )
                     .stdout
                     .strip

        expect(process('/opt/consul/bin/consul').args)
          .to(match(/-client=#{Regexp.escape(ip_address)}/))
      end
    end

    describe 'with client address provided' do
      before(:all) do
        create_env_file(
          endpoint_url: s3_endpoint_url,
          region: s3_bucket_region,
          bucket_path: s3_bucket_path,
          object_path: s3_env_file_object_path,
          env: {
            'CONSUL_CLIENT_ADDRESS' => '0.0.0.0'
          }
        )

        execute_docker_entrypoint(
          arguments: %w[agent -server],
          started_indicator: 'Started .* server'
        )
      end

      after(:all, &:reset_docker_backend)

      it 'includes the client option with the provided IP address' do
        expect(process('/opt/consul/bin/consul').args)
          .to(match(/-client=0\.0\.0\.0/))
      end
    end

    describe 'with both client interface and address provided' do
      before(:all) do
        create_env_file(
          endpoint_url: s3_endpoint_url,
          region: s3_bucket_region,
          bucket_path: s3_bucket_path,
          object_path: s3_env_file_object_path,
          env: {
            'CONSUL_CLIENT_INTERFACE' => 'eth0',
            'CONSUL_CLIENT_ADDRESS' => '0.0.0.0'
          }
        )

        execute_docker_entrypoint(
          arguments: ['agent', '-server'],
          started_indicator: 'Started .* server'
        )
      end

      after(:all, &:reset_docker_backend)

      it 'prioritises the provided address' do
        expect(process('/opt/consul/bin/consul').args)
          .to(match(/-client=0\.0\.0\.0/))
      end
    end

    describe 'with UI enabled flag provided and yes' do
      before(:all) do
        create_env_file(
          endpoint_url: s3_endpoint_url,
          region: s3_bucket_region,
          bucket_path: s3_bucket_path,
          object_path: s3_env_file_object_path,
          env: {
            'CONSUL_ENABLE_UI' => 'yes'
          }
        )

        execute_docker_entrypoint(
          arguments: %w[agent -server],
          started_indicator: 'Started .* server'
        )
      end

      after(:all, &:reset_docker_backend)

      it 'enables the UI' do
        expect(process('/opt/consul/bin/consul').args)
          .to(match(/-ui/))
      end
    end

    describe 'with UI enabled flag provided and not yes' do
      before(:all) do
        create_env_file(
          endpoint_url: s3_endpoint_url,
          region: s3_bucket_region,
          bucket_path: s3_bucket_path,
          object_path: s3_env_file_object_path,
          env: {
            'CONSUL_ENABLE_UI' => 'no'
          }
        )

        execute_docker_entrypoint(
          arguments: %w[agent -server],
          started_indicator: 'Started .* server'
        )
      end

      after(:all, &:reset_docker_backend)

      it 'does not enable the UI' do
        expect(process('/opt/consul/bin/consul').args)
          .not_to(match(/-ui/))
      end
    end

    describe 'with local configuration provided' do
      before(:all) do
        create_env_file(
          endpoint_url: s3_endpoint_url,
          region: s3_bucket_region,
          bucket_path: s3_bucket_path,
          object_path: s3_env_file_object_path,
          env: {
            'CONSUL_LOCAL_CONFIGURATION' => '{\"datacenter\": \"london\"}'
          }
        )

        execute_docker_entrypoint(
          arguments: %w[agent -server],
          started_indicator: 'Started .* server'
        )
      end

      after(:all, &:reset_docker_backend)

      it 'adds the configuration to the configuration directory' do
        expect(file('/opt/consul/config/local.json').content)
          .to(eq("{\"datacenter\": \"london\"}\n"))
      end
    end

    describe 'with EC2 auto join tag key and value' do
      before(:all) do
        create_env_file(
          endpoint_url: s3_endpoint_url,
          region: s3_bucket_region,
          bucket_path: s3_bucket_path,
          object_path: s3_env_file_object_path,
          env: {
            'CONSUL_EC2_AUTO_JOIN_TAG_KEY' => 'component',
            'CONSUL_EC2_AUTO_JOIN_TAG_VALUE' => 'consul-cluster'
          }
        )

        execute_docker_entrypoint(
          arguments: %w[agent -server],
          started_indicator: 'Started .* server'
        )
      end

      after(:all, &:reset_docker_backend)

      it 'includes retry join option' do
        retry_join_string =
          'provider=aws tag_key=component tag_value=consul-cluster'

        expect(process('/opt/consul/bin/consul').args)
          .to(match(
                /-retry-join #{retry_join_string}/
              ))
      end
    end

    describe 'with server addresses' do
      before(:all) do
        create_env_file(
          endpoint_url: s3_endpoint_url,
          region: s3_bucket_region,
          bucket_path: s3_bucket_path,
          object_path: s3_env_file_object_path,
          env: {
            'CONSUL_SERVER_ADDRESSES' =>
              'server1.example.com,server2.example.com'
          }
        )

        execute_docker_entrypoint(
          arguments: ['agent', '-server'],
          started_indicator: 'Started .* server'
        )
      end

      after(:all, &:reset_docker_backend)

      it 'includes retry join option' do
        expect(process('/opt/consul/bin/consul').args)
          .to(match(/-retry-join server1.example.com/)
                .and(match(/-retry-join server2.example.com/)))
      end
    end

    describe 'with expected servers provided' do
      before(:all) do
        create_env_file(
          endpoint_url: s3_endpoint_url,
          region: s3_bucket_region,
          bucket_path: s3_bucket_path,
          object_path: s3_env_file_object_path,
          env: {
            'CONSUL_EXPECTED_SERVERS' => '3'
          }
        )

        execute_docker_entrypoint(
          arguments: %w[agent -server],
          started_indicator: 'Started .* server'
        )
      end

      after(:all, &:reset_docker_backend)

      it 'includes bootstrap expect option' do
        expect(process('/opt/consul/bin/consul').args)
          .to(match(/-bootstrap-expect 3/))
      end
    end

    describe 'with privileged ports allowed' do
      before(:all) do
        create_env_file(
          endpoint_url: s3_endpoint_url,
          region: s3_bucket_region,
          bucket_path: s3_bucket_path,
          object_path: s3_env_file_object_path,
          env: {
            'CONSUL_ALLOW_PRIVILEGED_PORTS' => 'yes'
          }
        )

        execute_docker_entrypoint(
          arguments: %w[agent -server],
          started_indicator: 'Started .* server'
        )
      end

      after(:all, &:reset_docker_backend)

      it 'sets the correct capability on the consul binary' do
        capabilities = command('getcap /opt/consul/bin/consul').stdout

        expect(capabilities)
          .to(match(/cap_net_bind_service\+ep/))
      end
    end

    describe 'with permission management disabled' do
      before(:all) do
        create_env_file(
          endpoint_url: s3_endpoint_url,
          region: s3_bucket_region,
          bucket_path: s3_bucket_path,
          object_path: s3_env_file_object_path,
          env: {
            'CONSUL_DISABLE_PERM_MGMT' => 'yes'
          }
        )

        execute_command('chown -R root:root /opt/consul/data')
        execute_command('chown -R root:root /opt/consul/config')

        execute_docker_entrypoint(
          arguments: %w[agent -server],
          started_indicator: 'Started .* server'
        )
      end

      after(:all, &:reset_docker_backend)

      it 'does not change owning user of /opt/consul/data' do
        expect(file('/opt/consul/data')).to(be_owned_by('root'))
      end

      it 'does not change owning group of /opt/consul/data' do
        expect(file('/opt/consul/data')).to(be_grouped_into('root'))
      end

      it 'ensures the correct owning user of /opt/consul/config' do
        expect(file('/opt/consul/config')).to(be_owned_by('root'))
      end

      it 'ensures the correct owning group of /opt/consul/config' do
        expect(file('/opt/consul/config')).to(be_grouped_into('root'))
      end

      it 'runs with the root user' do
        expect(process('/opt/consul/bin/consul').user)
          .to(eq('root'))
      end

      it 'runs with the root group' do
        expect(process('/opt/consul/bin/consul').group)
          .to(eq('root'))
      end
    end
  end

  def reset_docker_backend
    Specinfra::Backend::Docker.instance.send :cleanup_container
    Specinfra::Backend::Docker.clear
  end

  def create_env_file(opts)
    create_object(opts
        .merge(content: (opts[:env] || {})
            .to_a
            .collect { |item| " #{item[0]}=\"#{item[1]}\"" }
            .join("\n")))
  end

  def execute_command(command_string)
    command = command(command_string)
    exit_status = command.exit_status
    unless exit_status == 0
      raise "\"#{command_string}\" failed with exit code: #{exit_status}"
    end

    command
  end

  def make_bucket(opts)
    execute_command('aws ' \
                    "--endpoint-url #{opts[:endpoint_url]} " \
                    's3 ' \
                    'mb ' \
                    "#{opts[:bucket_path]} " \
                    "--region \"#{opts[:region]}\"")
  end

  def copy_object(opts)
    execute_command("echo -n #{Shellwords.escape(opts[:content])} | " \
                    'aws ' \
                    "--endpoint-url #{opts[:endpoint_url]} " \
                    's3 ' \
                    'cp ' \
                    '- ' \
                    "#{opts[:object_path]} " \
                    "--region \"#{opts[:region]}\" " \
                    '--sse AES256')
  end

  def create_object(opts)
    make_bucket(opts)
    copy_object(opts)
  end

  def wait_for_contents(file, content)
    Octopoller.poll(timeout: 30) do
      docker_entrypoint_log = command("cat #{file}").stdout
      docker_entrypoint_log =~ /#{content}/ ? docker_entrypoint_log : :re_poll
    end
  rescue Octopoller::TimeoutError => e
    puts command("cat #{file}").stdout
    raise e
  end

  def execute_docker_entrypoint(opts)
    args = (opts[:arguments] || []).join(' ')
    logfile_path = '/tmp/docker-entrypoint.log'
    start_command = "docker-entrypoint.sh #{args} > #{logfile_path} 2>&1 &"
    started_indicator = opts[:started_indicator]

    execute_command(start_command)
    wait_for_contents(logfile_path, started_indicator)
  end
end
