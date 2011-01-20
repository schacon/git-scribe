require 'rubygems'
require 'nokogiri'

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

  BOOK_FILE = 'book.asc'

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

  def a2x(type)
    "a2x -f #{type} -d book -r resources"
  end

  def a2x_wss(type)
    a2x(type) + " --stylesheet=stylesheets/handbookish.css"
  end

  def do_pdf
    puts "GENERATING PDF"
    # TODO: syntax highlighting (fop?)
    `#{a2x('pdf')} --dblatex-opts "-P latex.output.revhistory=0" #{BOOK_FILE}`
    if $?.exitstatus == 0
      'book.pdf'
    end
  end

  def do_epub
    puts "GENERATING EPUB"
    # TODO: look for custom stylesheets
    `#{a2x_wss('epub')} --epubcheck #{BOOK_FILE}`
    puts 'exit status', $?.exitstatus
    'book.epub'
  end

  def do_html
    puts "GENERATING HTML"
    # TODO: look for custom stylesheets
    puts `#{a2x_wss('xhtml')} -v #{BOOK_FILE}`
    styledir = File.expand_path(File.join(Dir.pwd, 'stylesheets'))
    puts cmd = "asciidoc -a stylesdir=#{styledir} -a theme=handbookish #{BOOK_FILE}"
    `#{cmd}`
    puts 'exit status', $?.exitstatus
    'book.html'
  end

  def do_site
    puts "GENERATING SITE"
    # TODO: check if html was already done
    puts `asciidoc -b docbook #{BOOK_FILE}`
    xsldir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'xsl'))
    puts "xsltproc --stringparam html.stylesheet stylesheets/handbookish.css --nonet #{xsldir}/chunked.xsl book.xml"
    `xsltproc --stringparam html.stylesheet stylesheets/handbookish.css --nonet #{xsldir}/chunked.xsl book.xml`
    #source = File.read('book.html')
    #html = Nokogiri::XML.parse(source)
    # TODO: split html file into chunked site, apply templates
  end


  # create a new file by concatenating all the ones we find
  def gather_and_process
    files = Dir.glob("book/**/*.asciidoc")
    File.open("output/#{BOOK_FILE}", 'w+') do |f|
      files.each do |file|
        f.puts File.read(file)
      end
    end
    files = Dir.glob("book/image/**/*")
    FileUtils.cp_r(files, 'output/resources/')

    files = Dir.glob("book/include/**/*")
    FileUtils.cp_r(files, 'output/')
    pp files
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
