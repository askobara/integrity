require 'slack-ruby-client'

Slack.configure do |config|
  config.token = ENV['SLACK_API_TOKEN']
  fail 'Missing ENV[SLACK_API_TOKEN]!' unless ENV['SLACK_API_TOKEN']
end

module Integrity
  module Slack
    # Provide a Slack API client
    #
    # @return [Octokit::Client]
    def self.client
      @client ||= ::Slack::Web::Client.new
    end

    # class App < Sinatra::Base
    #   # Handle GitHub's events
    #   #
    #   # @return [Integer] Number of started builds
    #   post "/:token" do |token|
    #     unless token == Integrity.config.github_token
    #       halt 403
    #     end
    #
    #     payload = JSON.parse params[:payload]
    #
    #     case request.env['HTTP_X_GITHUB_EVENT']
    #     when "push"
    #       Payload::Push.build(payload).to_s
    #     when "pull_request"
    #       Payload::PullRequest.build(payload).to_s
    #     end
    #   end
    #
    # end
  end
end
