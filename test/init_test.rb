require File.expand_path "../test_helper", __FILE__

context "scribe init tests" do
  setup do
    @scribe = GitScribe.new
  end

  test "can't init a scribe repo without a directory" do
    in_temp_dir do
      assert_raise RuntimeError do
        @scribe.init
      end
    end
  end

  test "can't init a scribe repo for existing dir" do
    in_temp_dir do
      Dir.mkdir('t')
      assert_raise RuntimeError do
        @scribe.init('t')
      end
    end
  end

  test "can init a scribe repo" do
    in_temp_dir do
      @scribe.init('t')
      files = Dir.glob('t/**/*', File::FNM_DOTMATCH)
      assert files.include? "t/book/book.asc"
      assert files.include? "t/LICENSE"
      assert files.include? "t/README.asciidoc"
      assert files.include? "t/.gitscribe"
      assert files.include? "t/.gitignore"
      assert files.include? "t/.git"
    end
  end
end
