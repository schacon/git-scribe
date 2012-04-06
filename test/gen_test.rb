require File.expand_path "../test_helper", __FILE__

context "scribe gen tests" do
  setup do
    @scribe = GitScribe.new
  end

  test "will not respond to non-thing" do
    assert_raise RuntimeError do
      @scribe.gen('mofo')
    end
  end

  test "scribe don't crash on symlinks when run twice" do
    in_temp_dir do
      @scribe.init('t')
      Dir.chdir('t') do
        FileUtils.mkdir_p 'book/includes/sub1'
        FileUtils.mkdir_p 'book/includes/sub2'
        FileUtils.touch 'book/includes/sub1/real_file'
        FileUtils.ln_s '../sub1/real_file', 'book/includes/sub2/link_file'

        assert_nothing_raised do
          @scribe.gen('html')
          @scribe.gen('html')
        end
      end
    end
  end

  test "scribe can generate single page html" do
    in_temp_dir do
      @scribe.init('t')
      Dir.chdir('t') do
      file = @scribe.gen('html')
        assert_equal 'book.html', file
        out = Dir.glob('output/**/*')
        assert out.include? 'output/book.html'
        assert out.include? 'output/images'
        assert out.include? 'output/stylesheets/scribe.css'
      end
    end
  end

  test "scribe can generate site html" do
    in_temp_dir do
      @scribe.init('t')
      Dir.chdir('t') do
        data = @scribe.gen('site')
        out = Dir.glob('output/**/*')
        assert out.include? 'output/index.html'
        assert out.include? 'output/the_first_chapter.html'
        assert out.include? 'output/the_second_chapter.html'
        assert out.include? 'output/images'
        assert out.include? 'output/stylesheets/scribe.css'
      end
    end
  end

  test "scribe can generate site with syntax highlighting" do
    in_temp_dir do
      @scribe.init('t')
      Dir.chdir('t') do
        @scribe.gen('site')
        html = Nokogiri::HTML(File.read('output/the_first_chapter.html'))
        assert html.at_css "b:contains('char')"
      end
    end
  end


  test "scribe can generate a pdf" do
    in_temp_dir do
      @scribe.init('t')
      Dir.chdir('t') do
        data = @scribe.gen('pdf')
        assert_equal data, 'book.pdf'
        out = Dir.glob('output/**/*')
        assert out.include? 'output/book.pdf'
      end
    end
  end

  test "scribe can generate a pdf with syntax highlighting" do
    in_temp_dir do
      @scribe.init('t')
      Dir.chdir('t') do
        @scribe.gen('pdf')
        fo = Nokogiri::XML(File.read('output/book.fo'))
        fo.remove_namespaces!
        assert fo.at_css "inline[font-weight=bold][color=blue]:contains('char')"
      end
    end
  end

  test "scribe can generate a epub" do
    in_temp_dir do
      @scribe.init('t')
      Dir.chdir('t') do
      data = @scribe.gen('epub')
        assert_equal 'book.epub', data
        out = Dir.glob('output/**/*')
        assert out.include? 'output/book.epub'
      end
    end
  end

  test "scribe can generate a mobi" do
    in_temp_dir do
      @scribe.init('t')
      Dir.chdir('t') do
      data = @scribe.gen('mobi')
        assert_equal data, 'book.mobi'
        out = Dir.glob('output/**/*')
        assert out.include? 'output/book.mobi'
      end
    end
  end

  test "scribe can generate docbook" do
    in_temp_dir do
      @scribe.init('t')
      Dir.chdir('t') do
      data = @scribe.gen('docbook')
        assert_equal data, 'book.xml'
        out = Dir.glob('output/**/*')
        assert out.include? 'output/book.xml'
      end
    end
  end

  xtest "scribe can generate all" do
  end

  xtest "scribe doesn't regen already generated assets" do
  end
end
