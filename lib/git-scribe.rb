require 'rubygems'
require 'nokogiri'
require 'liquid'
require 'yaml'
require 'grit'

require 'git-scribe/generate'
require 'git-scribe/check'
require 'git-scribe/init'

require 'fileutils'
require 'pp'

class GitScribe

  include Init
  include Check
  include Generate

  attr_accessor :subcommand, :args, :options
  attr_reader :info

  #Allow overrides of the config files so we let the user have multiple versions of the book
  #maybe multiple languages or different formats
  BOOK_FILE = ENV["GITSCRIBE_BOOK_FILE"]
  BOOK_FILE ||= 'book.asc'
  OUTPUT_TYPES = ['docbook', 'html', 'pdf', 'epub', 'mobi', 'site', 'ebook']
  SCRIBE_ROOT = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  def initialize
    @subcommand = nil
    @args = []
    @options = {}
    configfilename =  ENV["GITSCRIBE_CONFIG_FILE"]
    configfilename ||= '.gitscribe'
    @config = YAML::parse(File.open(local(configfilename))).transform rescue {}
    @decorate = Decorator.new
  end

  ## COMMANDS ##

  def die(message)
    raise message
  end

  def local(file)
    File.expand_path(File.join(Dir.pwd, file))
  end

  def base(file)
    File.join(SCRIBE_ROOT, file)
  end

  # API/DATA HELPER FUNCTIONS #

  def git(subcommand)
    `git #{subcommand}`.chomp
  end

  def first_arg(args)
    Array(args).shift
  end

  # eventually we'll want to log this or have it retrievable elsehow
  def info(message)
    @info ||= []
    @info << message
  end

end
