module Integrity
  class ProjectFinder
    attr_reader :repo

    def self.find(repo)
      new(repo).find
    end

    def initialize(repo)
      @repo = repo
    end

    def find
      found = branches

      if found.empty? && Integrity.config.auto_branch?
        found = [forked]
      end

      found
    end

    # Filters founded repositories by the branch
    #
    # @return [DataMapper::Collection]
    def branches
      all.all(:branch => repo.branch)
    end

    # @return [DataMapper::Collection, DataMapper::Resource]
    def branch
      all.first(:branch => repo.branch)
    end

    def forked
      if repo.fork?
        origin = Project.filter_by_uri(repo.origin.uri).first
      else
        origin = all.first
      end

      origin.fork(repo) if origin
    end

    # Search an repositories by the uri
    #
    # @return [DataMapper::Collection]
    def all
      @all ||= Project.filter_by_uri(repo.uri)
    end
  end
end
