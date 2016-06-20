require 'octokit'

require 'github/payload/push'
require 'github/payload/pull_request'

fail 'Missing ENV[GITHUB_ACCESS_TOKEN]!' unless ENV['GITHUB_ACCESS_TOKEN']

module Integrity
  module GitHub
    ACCESS_TOKEN = ENV['GITHUB_ACCESS_TOKEN']

    # Provide a GitHub API client
    #
    # @return [Octokit::Client]
    def self.client
      @client ||= Octokit::Client.new :access_token => ACCESS_TOKEN
    end

    class App < Sinatra::Base
      configure do
        enable :logging, :dump_errors, :raise_errors
      end

      # Handle GitHub's events
      #
      # @return [Integer] Number of started builds
      post "/:token" do |token|
        unless token == Integrity.config.github_token
          halt 403
        end

        payload = JSON.parse params[:payload]

        case request.env['HTTP_X_GITHUB_EVENT']
        when "push"
          Payload::Push.build(payload).to_s
        when "pull_request"
          Payload::PullRequest.build(payload).to_s
        end
      end

    end
  end
end
