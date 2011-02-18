require 'rubygems'
require 'nokogiri'
require 'liquid'
require 'subcommand'

require 'fileutils'
require 'pp'

class GitScribe

  include Subcommands

  BOOK_FILE = 'book.asc'
  OUTPUT_TYPES = ['pdf', 'epub', 'mobi', 'html', 'site']
  SCRIBE_ROOT = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  def initialize

    @options = {}
    global_options do |opts|
      opts.banner = "Usage: #{$0} [options] [subcommand [options]]"
      opts.description = "git-scribe helps you write books with the power of Git"
      opts.separator ""
      opts.separator "Global options are:"
      opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
        @options[:verbose] = v
      end
    end

    command :init do |opts|
      opts.banner = "Usage: git scribe init (directory)"
      opts.description = "initialize a new book layout"
      opts.on("-l", "--lang", "choose a default language (en)") do |v|
        @options[:lang] = lang || 'en'
      end
    end

    command :gen do |opts|
      opts.banner = "Usage: git scribe gen [options]"
      opts.description = "generate digital formats"
    end

    @command = opt_parse
  end

  def self.start
    GitScribe.new.run
  end

  def run
    if @command && self.respond_to?(@command)
      self.send @command
    else
      help
    end
  end

  ## COMMANDS ##
 

  def die(message)
    raise message
  end

  # start a new scribe directory with skeleton structure
  def init
    name = ARGV.shift
    die("needs a directory name") if !name
    die("directory already exists") if File.exists?(name)

    puts "inititalizing #{name}"
    from_stdir = File.join(SCRIBE_ROOT, 'template')
    FileUtils.cp_r from_stdir, name
  end

  # check that we have everything needed
  def check
    # check for asciidoc
    if !check_can_run('asciidoc')
      puts "asciidoc is not present, please install it for anything to work"
    else
      puts "asciidoc - ok"
    end

    # check for xsltproc
    if !check_can_run('xsltproc --version')
      puts "xsltproc is not present, please install it for html generation"
    else
      puts "xsltproc - ok"
    end

    # check for a2x - should be installed with asciidoc, but you never know
    if !check_can_run('a2x')
      puts "a2x is not present, please install it for epub generation"
    else
      puts "a2x - ok"
    end

    # check for fop
    if !check_can_run('fop -version')
      puts "fop is not present, please install for PDF generation"
    else
      puts "fop - ok"
    end
  end

  def check_can_run(command)
    `#{command} 2>&1`
    $?.exitstatus == 0
  end
  # generate the new media
  def gen
    type = ARGV.shift || 'all'
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
      `rm #{BOOK_FILE}`
    end
  end

  def prepare_output_dir
    Dir.mkdir('output') rescue nil
    Dir.chdir('output') do
      Dir.mkdir('stylesheets') rescue nil
      puts SCRIBE_ROOT
      from_stdir = File.join(SCRIBE_ROOT, 'stylesheets')
      pp from_stdir
      FileUtils.cp_r from_stdir, '.'
    end
  end

  def a2x(type)
    "a2x -f #{type} -d book "
  end

  def a2x_wss(type)
    a2x(type) + " --stylesheet=stylesheets/handbookish.css"
  end

  def do_pdf
    puts "GENERATING PDF"
    # TODO: syntax highlighting (fop?)
    puts `asciidoc -b docbook #{BOOK_FILE}`
    strparams = {'callout.graphics' => 0,
                 'navig.graphics' => 0,
                 'admon.textlabel' => 1,
                 'admon.graphics' => 0}
    param = strparams.map { |k, v| "--stringparam #{k} #{v}" }.join(' ')
    puts cmd = "xsltproc  --nonet #{param} --output #{local('book.fo')} #{base('docbook-xsl/fo.xsl')} #{local('book.xml')}"
    puts `#{cmd}`
    cmd = "fop -fo #{local('book.fo')} -pdf #{local('book.pdf')}"
    puts `#{cmd}`
    #puts `#{a2x('pdf')} -v --fop #{BOOK_FILE}`
    if $?.exitstatus == 0
      'book.pdf'
    end
  end

  def local(file)
    File.expand_path(File.join(Dir.pwd, file))
  end

  def base(file)
    File.join(SCRIBE_ROOT, file)
  end

  def do_epub
    puts "GENERATING EPUB"
    # TODO: look for custom stylesheets
    `#{a2x_wss('epub')} -v #{BOOK_FILE}`
    puts 'exit status', $?.exitstatus
    'book.epub'
  end

  def do_html
    puts "GENERATING HTML"
    # TODO: look for custom stylesheets
    #puts `#{a2x_wss('xhtml')} -v #{BOOK_FILE}`
    styledir = local('stylesheets')
    puts cmd = "asciidoc -a stylesdir=#{styledir} -a theme=handbookish #{BOOK_FILE}"
    `#{cmd}`
    puts 'exit status', $?.exitstatus
    'book.html'
  end

  def do_site
    puts "GENERATING SITE"
    # TODO: check if html was already done
    puts `asciidoc -b docbook #{BOOK_FILE}`
    xsldir = base('docbook-xsl/xhtml')
    `xsltproc --stringparam html.stylesheet stylesheets/handbookish.css --nonet #{xsldir}/chunk.xsl book.xml`

    source = File.read('index.html')
    html = Nokogiri::HTML.parse(source, nil, 'utf-8')

    sections = []
    c = -1

    # each chapter
    html.css('.toc > dl').each do |section|
      section.children.each do |item|
        if item.name == 'dt' # section
          c += 1
          sections[c] ||= {'number' => c}
          link = item.css('a').first
          sections[c]['title'] = title = link.text
          sections[c]['href'] = href = link['href']
          clean_title = title.downcase.gsub(/[^a-z0-9\-_]+/, '_') + '.html'
          sections[c]['link'] = clean_title
          if href[0, 10] == 'index.html'
            sections[c]['link'] = 'title.html'
          end
          sections[c]['sub'] = []
        end
        if item.name == 'dd' # subsection
          item.css('dt').each do |sub|
            link = sub.css('a').first
            data = {}
            data['title'] = title = link.text
            data['href'] = href = link['href']
            data['link'] = sections[c]['link'] + '#' + href.split('#').last
            sections[c]['sub'] << data
          end
        end
      end
      puts
    end

    pp sections

    book_title = html.css('head > title').text
    content = html.css('body > div')[1]
    content.css('.toc').first.remove
    content = content.inner_html

    puts content 
    sections.each do |s|
      content.gsub!(s['href'], s['link'])
    end

    template_dir = File.join(SCRIBE_ROOT, 'site', 'default')

    # copy the template files in
    files = Dir.glob(template_dir + '/*')
    FileUtils.cp_r files, '.'

    Liquid::Template.file_system = Liquid::LocalFileSystem.new(template_dir)
    index_template = Liquid::Template.parse(File.read(File.join(template_dir, 'index.html')))
    page_template = Liquid::Template.parse(File.read(File.join(template_dir, 'page.html')))

    # write the index page
    main_data = { 
      'book_title' => book_title,
      'sections' => sections
    }
    File.open('index.html', 'w+') do |f|
      f.puts index_template.render( main_data )
    end

    # write the title page
    File.open('title.html', 'w+') do |f|
      data = { 
        'title' => sections.first['title'],
        'sub' => sections.first['sub'],
        'prev' => {'link' => 'index.html', 'title' => "Main"},
        'home' => {'link' => 'index.html', 'title' => "Home"},
        'next' => sections[1],
        'content' => content
      }
      data.merge!(main_data)
      f.puts page_template.render( data )
    end

    # write the other pages
    sections.each_with_index do |section, i|

      if i > 0 # skip title page
        source = File.read(section['href'])
        html = Nokogiri::HTML.parse(source, nil, 'utf-8')

        content = html.css('body > div')[1].to_html
        sections.each do |s|
          content.gsub!(s['href'], s['link'])
        end

        File.open(section['link'], 'w+') do |f|
          next_section = nil
          if i <= sections.size
            next_section = sections[i+1]
          end
          data = { 
            'title' => section['title'],
            'sub' => section['sub'],
            'prev' => sections[i-1],
            'home' => {'link' => 'index.html', 'title' => "Home"},
            'next' => next_section,
            'content' => content
          }
          data.merge!(main_data)
          f.puts page_template.render( data )
        end
        #File.unlink(section['href'])

        puts i
        puts section['title']
        puts section['href']
        puts section['link']
        puts
      end

      #File.unlink
    end
  end


  # create a new file by concatenating all the ones we find
  def gather_and_process
    files = Dir.glob("book/*")
    FileUtils.cp_r files, 'output'
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
