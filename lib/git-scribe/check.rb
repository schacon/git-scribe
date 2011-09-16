class GitScribe
  module Check
    # check that we have everything needed
    def check(args = [])
      status = {}

      # check for asciidoc
      if !check_can_run('asciidoc')
        info "asciidoc is not present, please install it for anything to work"
        status[:asciidoc] = false
      else
        info "asciidoc - ok"
        status[:asciidoc] = true
      end

      # check for xsltproc
      if !check_can_run('xsltproc --version')
        info "xsltproc is not present, please install it for html generation"
        status[:xsltproc] = false
      else
        info "xsltproc - ok"
        status[:xsltproc] = true
      end

      # check for a2x - should be installed with asciidoc, but you never know
      if !check_can_run('a2x')
        info "a2x is not present, please install it for epub generation"
        status[:a2x] = false
      else
        info "a2x      - ok"
        status[:a2x] = true
      end

      # check for source-highlight
      if !check_can_run('source-highlight --version')
        info "source-highlight is not present, please install it for source code highlighting"
        status[:highlight] = false
      else
        info "highlighting - ok"
        status[:highlight] = true
      end


      # check for fop
      if !check_can_run('fop -v -out list')
        info "fop is not present, please install for PDF generation"
        status[:fop] = false
      else
        info "fop      - ok"
        status[:fop] = true
      end

      # check for kindlegen
      if !check_can_run('kindlegen')
        info "kindlegen is not present, please install for mobi generation"
        status[:mobi] = false
      else
        info "kindlegen - ok"
        status[:mobi] = true
      end


      status
    end

    def check_can_run(command)
      `#{command} 2>&1`
      $?.success?
    end
  end
end
