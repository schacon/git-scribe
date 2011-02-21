require 'rubygems'
require 'nokogiri'
require 'liquid'

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

  BOOK_FILE = 'book.asc'
  OUTPUT_TYPES = ['pdf', 'epub', 'mobi', 'html', 'site']
  SCRIBE_ROOT = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  def initialize
    @subcommand = nil
    @args = []
    @options = {}
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
    puts message
  end

end
