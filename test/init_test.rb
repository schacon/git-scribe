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
end
