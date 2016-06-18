module Integrity
  module GitHub
    module Payload
      class PullRequest < Integrity::Payload::Base
        def deleted?
          payload["action"] == "closed"
        end

        def uri
          payload["pull_request"]["head"]["repo"]["clone_url"]
        end

        def branch
          payload["pull_request"]["head"]["ref"]
        end

        def commits
          @commits ||= [{
            :identifier   => payload["pull_request"]["head"]["sha"],
            :author       => payload["pull_request"]["user"]["login"],
            :message      => payload["pull_request"]["title"],
            :committed_at => payload["pull_request"]["head"]["repo"]["pushed_at"]
          }]
        end

        def fork_of
          @fork ||= Repository.new(
            payload["pull_request"]["base"]["repo"]["clone_url"],
            payload["pull_request"]["base"]["ref"]
          )
        end

        def head
          commits.first
        end

      end
    end
  end
end
