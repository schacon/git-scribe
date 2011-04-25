require File.expand_path "../test_helper", __FILE__

context "scribe check tests" do
  setup do
    @scribe = GitScribe.new
  end

  test "scribe can check for programs it needs" do
    status = @scribe.check
    assert_equal status.size, 6
  end

  # there no option '-version' for apache fop cli
  # it accepts only '-v' option but doesn't exit immediately.
  # it should be additional no-op flag provided (like '-out list')
  #
  # see http://svn.apache.org/repos/asf/xmlgraphics/fop/trunk/src/java/org/apache/fop/cli/CommandLineOptions.java
  test "scribe should correctly check fop availability" do
    assert_equal @scribe.check_can_run('fop -v -out list'), true
    assert_equal @scribe.check_can_run('fop -v'), false
    assert_equal @scribe.check_can_run('fop -version'), false
  end
end
