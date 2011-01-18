require 'fileutils'
require 'pp'

class GitScribe

  def initialize(args)
    @command = args.shift
    @args = args
  end

  def self.start(args)
    GitScribe.new(args).run
  end

  def run
    if @command && self.respond_to?(@command)
      self.send @command
    else
      help
    end
  end

  ## COMMANDS ##
 
  def help
    puts "No command: #{@command}"
    puts "TODO: tons of help"
  end

  # start a new scribe directory with skeleton structure
  def init
  end

  # check that we have everything needed
  def check
    # look for a2x (asciidoc, latex, xsltproc)
  end

  BOOK_FILE = 'book.asciidoc'

  OUTPUT_TYPES = ['pdf', 'epub', 'mobi', 'html', 'site']

  # generate the new media
  def gen
    type = @args.shift || 'all'
    prepare_output_dir

    gather_and_process

    types = type == 'all' ? OUTPUT_TYPES : [type]

    output = []
    Dir.chdir("output") do
      types.each do |out_type|
        call = 'do_' + out_type
        if self.respond_to? call
          self.send call
        else
          puts "NOT A THING: #{call}"
        end
      end
      # clean up
      # `rm #{BOOK_FILE}`
      # TODO: open media (?)
    end
  end

  def prepare_output_dir
    Dir.mkdir('output') rescue nil
    Dir.chdir('output') do
      Dir.mkdir('stylesheets') rescue nil
      from_stdir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'stylesheets'))
      FileUtils.cp_r from_stdir, '.'
    end
  end

  def do_pdf
    puts "GENERATING PDF"
    `a2x -f pdf -d book #{BOOK_FILE}`
    if $?.exitstatus == 0
      'book.pdf'
    end
  end

  def do_epub
    puts "GENERATING EPUB"
    `a2x -f epub -d book --epubcheck --stylesheet=stylesheets/handbookish.css #{BOOK_FILE}`
    puts 'exit status', $?.exitstatus
    'book.epub'
  end

  def do_html
    puts "GENERATING HTML"
    `a2x -f xhtml -d book --stylesheet=stylesheets/handbookish.css #{BOOK_FILE}`
    puts 'exit status', $?.exitstatus
    'book.html'
  end

  def do_site
    puts "GENERATING SITE"
    `a2x -f chunked -d book --stylesheet=stylesheets/handbookish.css #{BOOK_FILE}`
    puts 'exit status', $?.exitstatus
    'book.html'
  end


  # create a new file by concatenating all the ones we find
  def gather_and_process
    files = Dir.glob("book/**/*.asciidoc")
    File.open("output/#{BOOK_FILE}", 'w+') do |f|
      files.each do |file|
        f.puts File.read(file)
      end
    end
  end

  # DISPLAY HELPER FUNCTIONS #

  def l(info, size)
    clean(info)[0, size].ljust(size)
  end

  def r(info, size)
    clean(info)[0, size].rjust(size)
  end

  def clean(info)
    info.to_s.gsub("\n", ' ')
  end

  # API/DATA HELPER FUNCTIONS #

  def git(command)
    `git #{command}`.chomp
  end
end
