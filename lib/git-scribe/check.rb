class GitScribe
  module Check
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
  end
end
