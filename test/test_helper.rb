dir = File.dirname(File.expand_path(__FILE__))
$LOAD_PATH.unshift dir + '/../lib'
$TESTING = true

# Necessary to override stdlib: http://www.ruby-forum.com/topic/212974
require 'rubygems'
gem 'test-unit'
require 'test/unit'

require 'git-scribe'
require 'pp'
require 'tempfile'

##
# test/spec/mini 3
# http://gist.github.com/25455
# chris@ozmm.org
#
def context(*args, &block)
  return super unless (name = args.first) && block
  require 'test/unit'
  klass = Class.new(defined?(ActiveSupport::TestCase) ? ActiveSupport::TestCase : Test::Unit::TestCase) do
    def self.test(name, &block)
      define_method("test_#{name.gsub(/\W/,'_')}", &block) if block
    end
    def self.xtest(*args) end
    def self.setup(&block) define_method(:setup, &block) end
    def self.teardown(&block) define_method(:teardown, &block) end
  end
  (class << klass; self end).send(:define_method, :name) { name.gsub(/\W/,'_') }
  klass.class_eval &block
end

def in_temp_dir
  f = Tempfile.new('test')
  p = f.path
  f.unlink
  Dir.mkdir(p)
  Dir.chdir(p) do
    yield
  end
end
