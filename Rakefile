def command?(command)
  system("type #{command} > /dev/null 2>&1")
end

#
# Tests
#

task :default => :test

desc "Run the test suite"
task :test do
  rg = command?(:rg)
  Dir['test/**/*_test.rb'].each do |f|
    rg ? sh("rg #{f}") : ruby(f)
  end
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

