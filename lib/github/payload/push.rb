module Integrity
  module GitHub
    module Payload
      class Push < Integrity::Payload::Base
        def uri
          payload["repository"]["clone_url"]
        end

        def branch
          payload["ref"].split("refs/heads/").last
        end

        def commits
          @commits ||= payload["commits"].map do |commit|
            {
              :identifier   => commit["id"],
              :author       => normalize_author(commit["author"]),
              :message      => commit["message"],
              :committed_at => commit["timestamp"]
            }
          end
        end

        def head
          @head ||= {
            :identifier   => payload["head_commit"]["id"],
            :author       => normalize_author(payload["head_commit"]["author"]),
            :message      => payload["head_commit"]["message"],
            :committed_at => payload["head_commit"]["timestamp"]
          }
        end

        def deleted?
          payload["deleted"]
        end

        def created?
          payload["created"]
        end

        def normalize_author(author)
          "#{author["name"]} <#{author["email"]}>"
        end

      end
    end
  end
end
