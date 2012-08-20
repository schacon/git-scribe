class Decorator
  def initialize
    @dir = Dir.pwd
    @docbook = "#{@dir}/output/book.xml"
    @fop = "#{@dir}/output/book.fo"
  end

  def docbook
    xml = File.read(@docbook)

    xml.gsub!(
      /<programlisting(.+?)language="(\w+)"(.*?)>(.+?)<\/programlisting>/m
    ) { |m|
        %Q|<programlisting#{$1}language="#{$2}"#{$3}>| +
          %Q|//:::#{$2}:::\n#{$4}| +
        %Q|</programlisting>|
      }

    # File.write("#{@docbook}.tmp", xml)
    File.write(@docbook, xml)
  end

  # TODO better regexp. Mono font?
  def fop
    xml = File.read(@fop)

    xml.gsub!(
      /<fo:block(.+?)>\/\/:::(\w+):::\n(.+?)(<\/fo:block>)/m
    ) { |m|

        language = $2
        code = $3

        %Q|<fo:block#{$1}>| +
          highlight_fo(code, language) +
        %Q|#{$4}|
      }

    File.write("#{@fop}", xml)
  end


  private
  def highlight_fo(code, language)
    # $stderr.puts "****************"
    # $stderr.puts "**** #{language}"
    # $stderr.puts code

    # Don't highlight code with callouts
    return code if (code =~ /<fo:inline/)

    convert_bb_to_fo(
      bb_pygments(code, language)
    )
  end

  def bb_pygments(code, language)
    cmd = "pygmentize -O style=borland -f bb -l #{language}"

    code = CGI::unescapeHTML(code) if language == "html"

    output = ''
    Open3.popen3(cmd) do |stdin, stdout, stderr|
      stdin.write(code)
      stdin.close_write

      output = stdout.read #.tap{|bb| $stderr.puts bb}
    end

    return CGI::escapeHTML(output) if language == "html"
    output
  end

  def convert_bb_to_fo(bb)
    # $stderr.puts "----------"

    bb.gsub(
      /\[color=([^\]]+)\]\[i\](.+?)\[\/i\]\[\/color\]/m,
      '<fo:inline font-style="italic" color="\1">\2</fo:inline>'
    ).gsub(
      /\[color=([^\]]+)\]\[b\](.+?)\[\/b\]\[\/color\]/m,
      '<fo:inline font-weight="bold" color="\1">\2</fo:inline>'
    ).gsub(
      /\[i\](.+?)\[\/i\]/m,
      '<fo:inline font-style="italic">\1</fo:inline>'
    ).gsub(
      /\[b\](.+?)\[\/b\]/m,
      '<fo:inline font-weight="bold">\1</fo:inline>'
    ).gsub(
      /\[color=([^\]]+)\](.+?)\[\/color\]/m,
      '<fo:inline color="\1">\2</fo:inline>'
    )

    # .tap{|fo| $stderr.puts fo }
  end
end
