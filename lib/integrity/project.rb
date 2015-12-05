require "integrity/project/notifiers"

module Integrity
  class Project
    include DataMapper::Resource
    include Notifiers

    property :id,         Serial
    property :name,       String,   :required => true, :length => 255, :unique => true
    property :permalink,  String,   :length => 255
    property :uri,        URI,      :required => true, :length => 255
    property :branch,     String,   :required => true, :length => 255, :default => "master"
    property :command,    String,   :required => true, :length => 2000, :default => "rake"
    property :artifacts,  String,   :required => false, :length => 1000
    property :public,     Boolean,  :default  => true
    property :last_build_id, Integer, :required => false
    property :parent_id, Integer, :required => true, :default => 0

    timestamps :at

    default_scope(:default).update(:order => [:name.asc])

    has n, :builds
    has n, :notifiers

    belongs_to :last_build, 'Build'

    belongs_to :parent, 'Project'
    has n, :children, 'Project', :child_key => [:parent_id]

    before :save, :set_permalink
    before :save, :fix_line_endings

    before :destroy do
      builds.destroy!
    end

    # Filters projects with given uri
    #
    # @return [DataMapper::Collection]
    def self.filter_by_uri(uri)
      all(:uri.like => uri + '%')
    end

    # Filters projects by uri or by his origin if it's fork
    #
    # @param [Repository] repository
    # @return [DataMapper::Collection]
    def self.filter_by_repo(repository)
      found = filter_by_uri(repository.uri)

      if repository.fork? && found.empty?
        found = filter_by_uri(repository.origin.uri)
      end

      found
    end

    def get_artifacts
      artifacts.split(";")
    end

    def artifacts_empty?
      artifacts.nil? || artifacts.empty?
    end

    def repo
      @repo ||= Repository.new(uri, branch, origin)
    end

    def origin
      parent.repo if parent_id != 0 && parent
    end

    def build_head
      build(Commit.new(:identifier => "HEAD"))
    end

    def build(commit)
      _build = builds.create(:commit => {
        :identifier   => commit.identifier,
        :author       => commit.author,
        :message      => commit.message,
        :committed_at => commit.committed_at
      })
      _build.run
      _build
    end

    # Creates new project of given repository
    #
    # @param [Repository] repo
    def fork(repo)
      Project.raise_on_save_failure = true
      forked = Project.create(
        :name    => "#{repo.full_name} (#{repo.branch})",
        :uri     => repo.uri,
        :branch  => repo.branch,
        :command => command,
        :parent  => self,
        :public  => public?
      )

      # p forked.errors

      notifiers.each do |notifier|
        forked.notifiers.create(
          :name    => notifier.name,
          :enabled => notifier.enabled?,
          :config  => notifier.config
        )
      end

      forked
    end

    def github?
      repo.github?
    end

    # TODO lame, there is got to be a better way
    def sorted_builds
      builds(:order => [:created_at.desc, :id.desc])
    end

    def blank?
      last_build.nil?
    end

    def status
      blank? ? :blank : last_build.status
    end

    def human_status
      ! blank? && last_build.human_status
    end

    def human_duration
      ! blank? && last_build.human_duration
    end

    def attributes_for_json
      {
        "name" => name,
        "status" => status
      }
    end

    def to_json
      {
        "project" => attributes_for_json
      }.to_json
    end

    private
      def set_permalink
        attribute_set(:permalink,
          (name || "").
          downcase.
          gsub(/'s/, "s").
          gsub(/&/, "and").
          gsub(/[^a-z0-9]+/, "-").
          gsub(/-*$/, "")
        )
      end

      def fix_line_endings
        command = self.command
        unless command.empty?
          command = command.gsub("\r\n", "\n").gsub("\r", "\n")
          attribute_set(:command, command)
        end
      end
  end
end
