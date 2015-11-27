require 'rake/testtask'
Rake::TestTask.new do |t|
  t.pattern = 'spec/*_spec.rb'
end

desc 'Tweet new trains'
task :tweet do
  require_relative 'pairings.rb'
end

task default: [:test]
