class GitScribe
  module Generate
    # generate the new media
    def gen(args = [])
      @done = {}  # what we've generated already

      type = first_arg(args) || 'all'
      prepare_output_dir

      gather_and_process

      types = type == 'all' ? OUTPUT_TYPES : [type]

      ret = false
      output = []
      Dir.chdir("output") do
        types.each do |out_type|
          call = 'do_' + out_type
          if self.respond_to? call
            ret = self.send call
          else
            die "NOT A THING: #{call}"
          end
        end
        # clean up
        `rm #{BOOK_FILE}`
        ret
      end
    end

    def prepare_output_dir
      Dir.mkdir('output') rescue nil
      Dir.chdir('output') do
        Dir.mkdir('stylesheets') rescue nil
        from_stdir = File.join(SCRIBE_ROOT, 'stylesheets')
        FileUtils.cp_r from_stdir, '.'
      end
    end

    def a2x(type)
      "a2x -f #{type} -d book "
    end

    def a2x_wss(type)
      a2x(type) + " --stylesheet=stylesheets/scribe.css"
    end

    def do_docbook
      return true if @done['docbook']
      info "GENERATING DOCBOOK"
      if ex("asciidoc -b docbook #{BOOK_FILE}")
        @done['docbook'] = true
        'book.xml'
      end
    end

    def do_pdf
      info "GENERATING PDF"
      do_docbook

      java_options = {
        'callout.graphics' => 0,
        'navig.graphics'   => 0,
        'admon.textlabel'  => 1,
        'admon.graphics'   => 0,
      }
      run_xslt "-o #{local('book.fo')} #{local('book.xml')} #{base('docbook-xsl/fo.xsl')}", java_options
      ex "fop -fo #{local('book.fo')} -pdf #{local('book.pdf')}"

      if $?.success?
        'book.pdf'
      end
    end

    def do_epub
      info "GENERATING EPUB"
      # TODO: look for custom stylesheets
      cmd = "#{a2x_wss('epub')} -v #{BOOK_FILE}"
      if ex(cmd)
        'book.epub'
      end
    end

    def do_mobi
      do_html
      info "GENERATING MOBI"
      generate_toc_files
      # generate book.opf
      cmd = "kindlegen -verbose book.opf -o book.mobi"
      if ex(cmd)
        'book.mobi'
      end
    end

    def do_html
      return true if @done['html']
      info "GENERATING HTML"
      # TODO: look for custom stylesheets
      stylesheet = local('stylesheets') + '/scribe.css'
      cmd = "asciidoc -a stylesheet=#{stylesheet} #{BOOK_FILE}"
      if ex(cmd)
        @done['html'] == true
        'book.html'
      end
    end

    def do_site
      info "GENERATING SITE"
      # TODO: check if html was already done

      ex "asciidoc -b docbook #{BOOK_FILE}"
      run_xslt "book.xml #{base('docbook-xsl/xhtml/chunk.xsl')}", "html.stylesheet" => 1

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
      end

      book_title = html.css('head > title').text
      content = html.css('body > div')[1]
      content.css('.toc').first.remove
      content = content.inner_html

      sections.each do |s|
        content.gsub!(s['href'], s['link'])
      end

      template_dir = File.join(SCRIBE_ROOT, 'site', 'default')

      # copy the template files in
      files = Dir.glob(template_dir + '/*')
      FileUtils.cp_r files, '.'

      index_template = liquid_template('index.html')
      page_template = liquid_template('page.html')

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

          info i
          info section['title']
          info section['href']
          info section['link']
        end

        #File.unlink
      end
      sections
    end

    def generate_toc_files
      # read book table of contents
      toc = []
      source = File.read("book.html")

      # get the book title
      book_title = 'Title'
      if t = /\<title>(.*?)<\/title\>/.match(source)
        book_title = t[0]
      end

      source.scan(/\<h([2|3]) id=\"(.*?)\"\>(.*?)\<\/h[2|3]\>/).each do |header|
        sec = {'id' => header[1], 'name' => header[2]}
        if header[0] == '2'
          toc << {'section' => sec, 'subsections' => []}
        else
          toc[toc.size - 1]['subsections'] << sec
        end
      end

      # write ncx table of contents
      ncx = File.open('book.ncx', 'w+')
      ncx.puts('<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE ncx PUBLIC "-//NISO//DTD ncx 2005-1//EN"
	"http://www.daisy.org/z3986/2005/ncx-2005-1.dtd">

<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1" xml:lang="en-US">
<head>
<meta name="dtb:depth" content="2"/>
<meta name="dtb:totalPageCount" content="0"/>
<meta name="dtb:maxPageNumber" content="0"/>
</head>
<docTitle><text>Title</text></docTitle>
<docAuthor><text>Author</text></docAuthor>
<navMap>
<navPoint class="toc" id="toc" playOrder="1">
<navLabel>
<text>Table of Contents</text>
</navLabel>
<content src="toc.html"/>
</navPoint>')

      chapters = 0
      toc.each do |section|
        chapters += 1
        ch = section['section']
        ncx.puts('<navPoint class="chapter" id="chapter_' + chapters.to_s + '" playOrder="' + (chapters + 1).to_s + '">')
        ncx.puts('<navLabel><text>' + ch['name'].to_s + '</text></navLabel>')
        ncx.puts('<content src="book.html#' + ch['id'].to_s + '"/>')
        ncx.puts('</navPoint>')
      end
      ncx.puts('</navMap></ncx>')
      ncx.close

      # build html toc
      # write ncx table of contents
      html = File.open('toc.html', 'w+')
      html.puts('<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head><title>Table of Contents</title></head><body>
<div><h1><b>TABLE OF CONTENTS</b></h1><br/>')

      chapters = 0
      toc.each do |section|
        chapters += 1
        ch = section['section']

        html.puts('<h3><b>Chapter ' + chapters.to_s + '<br/>')
        html.puts('<a href="book.html#' + ch['id'] + '">' + ch['name'] + '</a></b></h3><br/>')

        section['subsections'].each do |sub|
          html.puts('<a href="book.html#' + sub['id'] + '"><b>' + sub['name'] + '</b></a><br/>')
        end
      end
      html.puts('<h1 class="centered">* * *</h1></div></body></html>')
      html.close

      # build book.opf file
      opf_template = liquid_template('book.opf')
      File.open('book.opf', 'w+') do |f|
        lang   = @config['language'] || 'en'
        author = @config['author'] || 'Author'
        cover  = @config['cover'] || 'images/cover.jpg'
        data = {'title'    => book_title,
                'language' => lang,
                'author'   => author,
                'pubdate'  => Time.now.strftime("%Y-%m-%d"),
                'cover_image' => cover}
        f.puts opf_template.render( data )
      end
    end


    def liquid_template(file)
      template_dir = File.join(SCRIBE_ROOT, 'site', 'default')
      Liquid::Template.parse(File.read(File.join(template_dir, file)))
    end


    # create a new file by concatenating all the ones we find
    def gather_and_process
      files = Dir.glob("book/*")
      FileUtils.cp_r files, 'output', :remove_destination => true
    end

    def ex(command)
      out = `#{command} 2>&1`
      info out
      $?.success?
    end

    private

    def windows?
      RbConfig::CONFIG['host_os'] =~ /mswin|windows|mingw|cygwin/i
    end

    def classpath_delimiter
      if windows?
        ";"
      else
        ":"
      end
    end

    def run_xslt(jar_arguments, java_options)
      ex <<-SH
        java -cp "#{base('vendor/saxon.jar')}#{classpath_delimiter}#{base('vendor/xslthl-2.0.2.jar')}" \
             -Dxslthl.config=file://"#{base('docbook-xsl/highlighting/xslthl-config.xml')}" \
             #{java_options.map { |k, v| "-D#{k}=#{v}" }.join(' ')} \
             com.icl.saxon.StyleSheet \
             #{jar_arguments}
      SH
    end
  end
end
