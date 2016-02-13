module Integrity
  module Payload
    class Base
      attr_reader :payload

      def self.build(payload)
        new(payload).build
      end

      def initialize(payload)
        @payload = payload
      end

      def build
        PayloadBuilder.build(self)
      end

      def repo
        @repo ||= Repository.new(uri, branch, fork_of)
      end

      def head
        raise NotImplementedError.new(
          "Your GitHub events module should provide a #head method"
        )
      end

      def commits
        raise NotImplementedError.new(
          "Your GitHub events module should provide a #commits method"
        )
      end

      def uri
        raise NotImplementedError.new(
          "Your GitHub events module should provide a #uri method"
        )
      end

      def branch
        raise NotImplementedError.new(
          "Your GitHub events module should provide a #branch method"
        )
      end

      def fork_of
        nil
      end

      def deleted?
        false
      end

      def created?
        false
      end
    end
  end
end
