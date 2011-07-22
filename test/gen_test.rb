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

  test "scribe can generate single page html" do
    in_temp_dir do
      @scribe.init('t')
      Dir.chdir('t') do
        ret = @scribe.gen('html')
        assert_equal true, ret
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
        @scribe.gen('site')
        out = Dir.glob('output/**/*')
        assert out.include? 'output/site/index.html'
        assert out.include? 'output/site/the_first_chapter.html'
        assert out.include? 'output/site/the_second_chapter.html'
        assert out.include? 'output/site/images'
        assert out.include? 'output/site/stylesheets/scribe.css'
      end
    end
  end

  test "scribe can generate a pdf" do
    in_temp_dir do
      @scribe.init('t')
      Dir.chdir('t') do
        ret = @scribe.gen('pdf')
        assert_equal true, ret
        out = Dir.glob('output/**/*')
        assert out.include? 'output/book.pdf'
      end
    end
  end

  test "scribe can generate a epub" do
    in_temp_dir do
      @scribe.init('t')
      Dir.chdir('t') do
        ret = @scribe.gen('epub')
        assert_equal true, ret
        out = Dir.glob('output/**/*')
        assert out.include? 'output/book.epub'
      end
    end
  end

  test "scribe generates an epub with a cover" do
    in_temp_dir do
      @scribe.init('t')
      Dir.chdir('t') do
        ret = @scribe.gen('epub')
        assert_equal true, ret
        `unzip output/book.epub 2>&1 > /dev/null`
        opf = File.read('OEBPS/content.opf')
        assert opf.include? 'id="cover-image" href="images/cover.jpg"'
      end
    end
  end

  test "scribe can generate a mobi" do
    in_temp_dir do
      @scribe.init('t')
      Dir.chdir('t') do
        ret = @scribe.gen('mobi')
        assert_equal true, ret
        out = Dir.glob('output/**/*')
        assert out.include? 'output/book.mobi'
      end
    end
  end

  test "scribe generates a mobi with a cover and TOC" do
    in_temp_dir do
      @scribe.init('t')
      Dir.chdir('t') do
        ret = @scribe.gen('mobi')
        assert_equal true, ret
        `unzip output/book.mobi 2>&1 > /dev/null`
        opf = File.read('OEBPS/content.opf')
        assert opf.include? 'id="cover-image" href="images/cover.jpg"'
        assert opf.include? 'href="toc.html" type="toc"'
      end
    end
  end

  test "scribe can generate an ebook ZIP" do
    in_temp_dir do
      @scribe.init('t')
      Dir.chdir('t') do
        ret = @scribe.gen('ebook')
        assert_equal true, ret
        out = Dir.glob('output/**/*')
        assert out.include? 'output/book_title/book_title.mobi'
        assert out.include? 'output/book_title/book_title.epub'
        assert out.include? 'output/book_title/book_title.pdf'
        assert out.include? 'output/book_title.zip'
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
