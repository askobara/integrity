require 'slack-ruby-client'

Slack.configure do |config|
  config.token = ENV['SLACK_API_TOKEN']
  fail 'Missing ENV[SLACK_API_TOKEN]!' unless config.token
end

# client = Slack::Web::Client.new
# user = client.users_info(user: '@askobara').user
# client.chat_postMessage(channel: user.id, text: 'Hello World', as_user: true)
#
module Integrity
  module Slack
    # Slack.configure do |config|
    #   config.token = ACCESS_TOKEN
    # end

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
