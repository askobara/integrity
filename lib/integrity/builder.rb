module Integrity
  class Builder
    def self.build(_build, logger)
      new(_build, logger).build
    end

    def initialize(build, logger)
      @build     = build
      @logger    = logger

      @build.raise_on_save_failure = true
    end

    def build
      begin
        start
        run { |chunk| add_output chunk }
      rescue Interrupt, SystemExit
        raise
      rescue Exception => e
        # Here is very bad solution, because you don't see an Exception in the
        # STDOUT if Integrity::Build will raise it in save or update methods
        fail e
      else
        complete
      end
      notify
    end

    def start
      @logger.info "Started building #{repo.uri} at #{commit}"
      @build.update(:started_at => Time.now)
      @build.project.enabled_notifiers.each { |n| n.notify_of_build_start(@build) }
      # checkout.run
      # checkout.metadata invokes git and may fail
      # @build.commit.raise_on_save_failure = true
      # @build.commit.update(checkout.metadata)
    end

    def run
      @result = runner.run(command) do |chunk|
        yield chunk
      end
    end

    def add_output(chunk)
      @build.update(:output => @build.output + chunk)
    end

    def complete
      @logger.info "Build #{commit} exited with #{@result.success} got:\n #{@result.output}"

      @build.update(
        :completed_at => Time.now,
        :successful   => @result.success,
        :output       => @result.output
      )
    end

    def fail(exception)
      failure_message = "#{exception.class}: #{exception.message}"

      @logger.info "Build #{commit} failed with an exception: #{failure_message}"

      failure_message << "\n\n"
      exception.backtrace.each do |line|
        failure_message << line << "\n"
      end

      @build.update(
        :completed_at => Time.now,
        :successful => false,
        :output => failure_message
      )
    end

    def notify
      @build.notify
    end

    def directory
      @build.build_directory
    end

    def repo
      @build.repo
    end

    def runner
      @runner ||= CommandRunner.new(@logger, Integrity.config.build_output_interval)
    end

    def command
      <<-SHELL
      #!/bin/bash

      set -e

      source /etc/profile

      if [[ -s ~/.bash_profile ]]; then
        source ~/.bash_profile
      fi

      ANSI_RED="\033[31;1m"
      ANSI_GREEN="\033[32;1m"
      ANSI_RESET="\033[0m"
      ANSI_CLEAR="\033[0K"

      cmd() {
        echo "⚙ $@"
        eval $@ || error $@

        return $?
      }

      error() {
        echo -e "${ANSI_RED}✗ The command \"$@\" failed and exited with $?.${ANSI_RESET}"
        exit 1
      }

      cmd export GIT_ASKPASS=#{File.join(Integrity.config.bin_dir, 'askpass')}

      if [[ ! -d #{directory}/.git ]]; then
        cmd git clone --depth=10 --no-single-branch #{repo.uri.to_s} #{directory}
      else
        cmd git -C #{directory} fetch origin
        cmd git -C #{directory} reset --hard origin/#{repo.branch}
      fi

      cmd cd #{directory}
      cmd git checkout -qf #{commit}

      if [[ -f .gitmodules ]]; then
        cmd git submodule init
        cmd git submodule update
      fi

      #{@build.command}

      exit 0
      SHELL
    end

    def commit
      @build.sha1
    end

  end
end
