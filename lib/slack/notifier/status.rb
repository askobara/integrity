require 'yaml'

module Integrity
  class Notifier
    class SlackStatus < Integrity::Notifier::Base

      attr_reader :config

      def self.to_haml
        File.read(File.dirname(__FILE__) + "/status.haml")
      end

      def convert_login(username)
        logins = credentials || {}

        '@' + (logins[username] || username)
      end

      def credentials
        data ||= YAML.load(File.open(Integrity.config.root_dir + "/credentials.yaml"))
      end

      def initialize(build, config={})
        super
        @user = Integrity::Slack.client.users_info(user: convert_login('askobara')).user
      end

      def deliver_failed_notification!
        notify_about_failed
      end

      def deliver!
        notify_about_failed unless build.successful
      end

      def notify_about_failed
        message = "<#{build_url}|Build ##{@build.id} was broken>"
        puts Integrity::Slack.client.chat_postMessage(channel: @user.id, text: message, as_user: true)
      end

    end
  end
end
