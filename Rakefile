def command?(command)
  system("type #{command} > /dev/null 2>&1")
end

#
# Tests
#

task :default => :test

require 'rake/testtask'
Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/*_test.rb']
  t.verbose = true
end

#
# Publishing
#

desc "Push a new version to Gemcutter"
task :publish do
  require 'git-scribe/version'

  sh "gem build git-scribe.gemspec"
  sh "gem push git-scribe-#{GitScribe::Version}.gem"
  sh "git tag v#{GitScribe::Version}"
  sh "git push origin v#{GitScribe::Version}"
  sh "git push origin master"
end

