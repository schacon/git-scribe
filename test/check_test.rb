require File.expand_path "../test_helper", __FILE__

context "scribe check tests" do
  setup do
    @scribe = GitScribe.new
  end

  test "scribe can check for programs it needs" do
    status = @scribe.check
    assert_equal status.size, 6
  end
end
