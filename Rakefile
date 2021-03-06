$LOAD_PATH.unshift File.join(File.dirname(__FILE__))
require "rake/testtask"
require "rake/clean"
require 'fileutils'

desc "Default: run all tests"
task :default => :test

desc "Run tests"
task :test => %w[test:unit test:acceptance]
namespace :test do
  desc "Run unit tests"
  Rake::TestTask.new(:unit) do |t|
    t.libs << "test"
    t.test_files = FileList["test/unit/*_test.rb"]
  end

  desc "Run acceptance tests"
  Rake::TestTask.new(:acceptance) do |t|
    t.libs << "test"
    t.test_files = FileList["test/acceptance/*_test.rb"]
  end
end

desc "Create the database"
task :db do
  require "init"
  DataMapper.auto_upgrade!

  Integrity::Project.all(:last_build_id => nil).each do |project|
    project.last_build = project.sorted_builds.first
    project.raise_on_save_failure = true
    project.save
  end
end

desc "Clean-up build directory"
task :cleanup do
  require "init"
  Integrity::Build.all(:completed_at.not => nil).each do |build|
    dir = build.build_directory
    dir.rmtree if dir.exist?
  end
end

namespace :jobs do
  desc "Clear the delayed_job queue."
  task :clear do
    require "init"
    require "integrity/delayed_builder"
    Delayed::Job.delete_all
  end

  desc "Start a delayed_job worker."
  task :work do
    require "init"
    require "integrity/delayed_builder"
    Delayed::Worker.new.start
  end
end

begin
  namespace :resque do
    require "init"
    require "resque/tasks"

    desc "Start a Resque worker for Integrity"
    task :work do
      ENV["QUEUE"] = "integrity"
      Rake::Task["resque:resque:work"].invoke
    end
  end
rescue LoadError
end

desc "Generate HTML documentation."
task :html => %w(
  doc/build
  doc/build/index.html
)

file "doc/build/index.html" => ["doc/htmlize",
  "doc/integrity.txt",
  "doc/integrity.css"] do |f|
  sh "cat doc/integrity.txt | doc/htmlize > #{f.name}"
end

task "doc/build" do
  FileUtils.mkdir_p('doc/build')
end

doc_dependencies = %w(
  integrity.css
  screenshot.png
)

doc_dependencies.each do |file|
  task "doc/build/#{file}" => "doc/#{file}" do
    FileUtils.cp("doc/#{file}", "doc/build/#{file}")
  end
  task :html => "doc/build/#{file}"
end

desc "Re-generate stylesheet"
file "lib/app/public/integrity.css" => "lib/app/views/integrity.sass" do |f|
  sh "sass lib/app/views/integrity.sass > #{f.name}"
end

CLOBBER.include("doc/build")
