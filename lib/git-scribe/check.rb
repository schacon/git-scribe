class GitScribe
  module Check
    # check that we have everything needed
    def check(args = [])
      status = {}

      # check for git
      if !check_can_run('git --version')
        info "git is not present, please install it for anything to work"
        status[:git] = true
      else
        info "git      - ok"
        status[:git] = false
      end

      # check for asciidoc
      if !check_can_run('asciidoc')
        info "asciidoc is not present, please install it for anything to work"
        status[:asciidoc] = true
      else
        info "asciidoc - ok"
        status[:asciidoc] = false
      end

      # check for xsltproc
      if !check_can_run('xsltproc --version')
        info "xsltproc is not present, please install it for html generation"
        status[:xsltproc] = true
      else
        info "xsltproc - ok"
        status[:xsltproc] = false
      end

      # check for a2x - should be installed with asciidoc, but you never know
      if !check_can_run('a2x')
        info "a2x is not present, please install it for epub generation"
        status[:a2x] = true
      else
        info "a2x      - ok"
        status[:a2x] = false
      end

      # check for fop
      if !check_can_run('fop -version')
        info "fop is not present, please install for PDF generation"
        status[:fop] = true
      else
        info "fop      - ok"
        status[:fop] = false
      end

      status
    end

    def check_can_run(command)
      `#{command} 2>&1`
      $?.exitstatus == 0
    end
  end
end
