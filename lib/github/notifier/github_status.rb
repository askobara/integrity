module Integrity
  class Notifier
    class GitHubStatus < Integrity::Notifier::Base
      attr_reader :config

      STATUS_SUCCESS = 'success'
      STATUS_FAILURE = 'failure'
      STATUS_PENDING = 'pending'
      STATUS_ERROR = 'error'

      def self.to_haml
        File.read(File.dirname(__FILE__) + "/github_status.haml")
      end

      def initialize(build, config={})
        @repo_full_name = if build.repo.fork?
                            build.repo.origin.full_name
                          else
                            build.repo.full_name
                          end
        @commit_sha = build.commit.identifier

        super
      end

      def deliver_started_notification!
        create_status STATUS_PENDING if config["notify_pending"] == "1"
      end

      def deliver_failed_notification!
        create_status STATUS_ERROR
      end

      def deliver!
        create_status build.successful? ? STATUS_SUCCESS : STATUS_FAILURE
      end

      private
      def create_status(status)
        Integrity::GitHub.client.create_status(@repo_full_name, @commit_sha, status)
        Integrity.config.logger.info "#{@repo_full_name} #{@commit_sha} #{status}"
      end

    end
  end
end
