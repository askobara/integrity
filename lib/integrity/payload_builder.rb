module Integrity
  class PayloadBuilder
    attr_reader :payload

    def self.build(payload)
      new(payload).build
    end

    def initialize(payload)
      @payload = payload
    end

    def build
      if Integrity.config.trim_branches? && payload.deleted?
        projects.each { |project| project.destroy }
        0
      else
        builds.each { |build| build.run }.size
      end
    end

    def builds
      @builds ||=
        projects.inject([]) do |acc, project|
          acc.concat commits.map { |c| project.builds.create(:commit => c) }
        end
    end

    def commits
      @commits ||= Integrity.config.build_all? ? payload.commits : [payload.head].compact
    end

    def projects
      @projects ||= ProjectFinder.find(payload.repo)
    end
  end
end
