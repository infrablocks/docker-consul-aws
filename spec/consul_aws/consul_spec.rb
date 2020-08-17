require 'spec_helper'

describe 'consul-aws consul' do
  metadata_service_url = 'http://metadata:1338'
  s3_endpoint_url = 'http://s3:4566'
  s3_bucket_region = 'us-east-1'
  s3_bucket_path = 's3://bucket'
  s3_env_file_object_path = 's3://bucket/env-file.env'

  environment = {
      'AWS_METADATA_SERVICE_URL' => metadata_service_url,
      'AWS_ACCESS_KEY_ID' => "...",
      'AWS_SECRET_ACCESS_KEY' => "...",
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

    it "includes the consul command" do
      expect(command('/opt/consul/bin/consul --version').stdout)
          .to match /1.8.3/
    end
  end

  describe 'entrypoint' do
    describe 'with agent subcommand' do
      before(:all) do
        create_env_file(
            endpoint_url: s3_endpoint_url,
            region: s3_bucket_region,
            bucket_path: s3_bucket_path,
            object_path: s3_env_file_object_path)

        execute_docker_entrypoint(
            arguments: ["agent", "-server"],
            started_indicator: "Started .* server")
      end

      after(:all, &:reset_docker_backend)

      it "runs a consul agent" do
        expect(process('/opt/consul/bin/consul')).to be_running
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
            .to(match(/-data-dir=\/opt\/consul\/data/))
      end

      it 'uses the correct config directory' do
        expect(process('/opt/consul/bin/consul').args)
            .to(match(/-config-dir=\/opt\/consul\/config/))
      end

      it 'uses json logging' do
        expect(process('/opt/consul/bin/consul').args)
            .to(match(/-log-json/))
      end
    end

    describe 'without bind interface provided' do
      before(:all) do
        create_env_file(
            endpoint_url: s3_endpoint_url,
            region: s3_bucket_region,
            bucket_path: s3_bucket_path,
            object_path: s3_env_file_object_path)

        execute_docker_entrypoint(
            arguments: ["agent", "-server"],
            started_indicator: "Started .* server")
      end

      after(:all, &:reset_docker_backend)

      it "does not include the bind option" do
        expect(process('/opt/consul/bin/consul').args)
            .not_to(match(/-bind/))
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
            })

        execute_docker_entrypoint(
            arguments: ["agent", "-server"],
            started_indicator: "Started .* server")
      end

      after(:all, &:reset_docker_backend)

      it "includes the bind option with the correct IP address" do
        ip_address = command(
            "ip -o -4 addr list eth0 " +
                "| head -n1 " +
                "| awk '{print $4}' " +
                "| cut -d/ -f1")
            .stdout
            .strip

        expect(process('/opt/consul/bin/consul').args)
            .to(match(/-bind=#{Regexp.escape(ip_address)}/))
      end
    end

    describe 'without client interface provided' do
      before(:all) do
        create_env_file(
            endpoint_url: s3_endpoint_url,
            region: s3_bucket_region,
            bucket_path: s3_bucket_path,
            object_path: s3_env_file_object_path)

        execute_docker_entrypoint(
            arguments: ["agent", "-server"],
            started_indicator: "Started .* server")
      end

      after(:all, &:reset_docker_backend)

      it "does not include the client option" do
        expect(process('/opt/consul/bin/consul').args)
            .not_to(match(/-client/))
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
            })

        execute_docker_entrypoint(
            arguments: ["agent", "-server"],
            started_indicator: "Started .* server")
      end

      after(:all, &:reset_docker_backend)

      it "includes the client option with the correct IP address" do
        ip_address = command(
            "ip -o -4 addr list eth0 " +
                "| head -n1 " +
                "| awk '{print $4}' " +
                "| cut -d/ -f1")
            .stdout
            .strip

        expect(process('/opt/consul/bin/consul').args)
            .to(match(/-client=#{Regexp.escape(ip_address)}/))
      end
    end

    describe 'without client address provided' do
      before(:all) do
        create_env_file(
            endpoint_url: s3_endpoint_url,
            region: s3_bucket_region,
            bucket_path: s3_bucket_path,
            object_path: s3_env_file_object_path)

        execute_docker_entrypoint(
            arguments: ["agent", "-server"],
            started_indicator: "Started .* server")
      end

      after(:all, &:reset_docker_backend)

      it "does not include the client option" do
        expect(process('/opt/consul/bin/consul').args)
            .not_to(match(/-client/))
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
            })

        execute_docker_entrypoint(
            arguments: ["agent", "-server"],
            started_indicator: "Started .* server")
      end

      after(:all, &:reset_docker_backend)

      it "includes the client option with the provided IP address" do
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
            })

        execute_docker_entrypoint(
            arguments: ["agent", "-server"],
            started_indicator: "Started .* server")
      end

      after(:all, &:reset_docker_backend)

      it "prioritises the provided address" do
        expect(process('/opt/consul/bin/consul').args)
            .to(match(/-client=0\.0\.0\.0/))
      end
    end

    describe 'without UI enabled flag' do
      before(:all) do
        create_env_file(
            endpoint_url: s3_endpoint_url,
            region: s3_bucket_region,
            bucket_path: s3_bucket_path,
            object_path: s3_env_file_object_path,
        )

        execute_docker_entrypoint(
            arguments: ["agent", "-server"],
            started_indicator: "Started .* server")
      end

      after(:all, &:reset_docker_backend)

      it "does not enable the UI" do
        expect(process('/opt/consul/bin/consul').args)
            .not_to(match(/-ui/))
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
            })

        execute_docker_entrypoint(
            arguments: ["agent", "-server"],
            started_indicator: "Started .* server")
      end

      after(:all, &:reset_docker_backend)

      it "enables the UI" do
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
            })

        execute_docker_entrypoint(
            arguments: ["agent", "-server"],
            started_indicator: "Started .* server")
      end

      after(:all, &:reset_docker_backend)

      it "does not enable the UI" do
        expect(process('/opt/consul/bin/consul').args)
            .not_to(match(/-ui/))
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
      raise RuntimeError,
          "\"#{command_string}\" failed with exit code: #{exit_status}"
    end
    command
  end

  def create_object(opts)
    execute_command('aws ' +
        "--endpoint-url #{opts[:endpoint_url]} " +
        's3 ' +
        'mb ' +
        "#{opts[:bucket_path]} " +
        "--region \"#{opts[:region]}\"")
    execute_command("echo -n #{Shellwords.escape(opts[:content])} | " +
        'aws ' +
        "--endpoint-url #{opts[:endpoint_url]} " +
        's3 ' +
        'cp ' +
        '- ' +
        "#{opts[:object_path]} " +
        "--region \"#{opts[:region]}\" " +
        '--sse AES256')
  end

  def execute_docker_entrypoint(opts)
    logfile_path = '/tmp/docker-entrypoint.log'
    arguments = opts[:arguments] && !opts[:arguments].empty? ?
        " #{opts[:arguments].join(' ')}" : ''

    execute_command(
        "docker-entrypoint.sh#{arguments} > #{logfile_path} 2>&1 &")

    begin
      Octopoller.poll(timeout: 5) do
        docker_entrypoint_log = command("cat #{logfile_path}").stdout
        docker_entrypoint_log =~ /#{opts[:started_indicator]}/ ?
            docker_entrypoint_log :
            :re_poll
      end
    rescue Octopoller::TimeoutError => e
      puts command("cat #{logfile_path}").stdout
      raise e
    end
  end
end
