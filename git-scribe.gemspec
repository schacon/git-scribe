$LOAD_PATH.unshift 'lib'

Gem::Specification.new do |s|
  s.name              = "git-scribe"
  s.version           = "0.0.1"
  s.date              = Time.now.strftime('%Y-%m-%d')
  s.summary           = "git-scribe is an authors toolkit for writing and publishing books"
  s.homepage          = "http://github.com/schacon/git-scribe"
  s.email             = "schacon@gmail.com"
  s.authors           = [ "Scott Chacon" ]
  s.has_rdoc          = false

  s.files             = %w( LICENSE README.asciidoc )
  s.files            += Dir.glob("lib/**/*")
  s.files            += Dir.glob("bin/**/*")

  s.executables       = %w( git-scribe )

  s.description       = <<desc
  git-scribe is a workflow tool for starting, writing, reviewing and publishing
  multiple forms of a book.  it allows you to use asciidoc plain text markup to
  write, review and translate a work and provides a simple toolkit for generating
  common digital outputs for publishing - epub, mobi, pdf and html.  it is also
  integrated into github functionality, letting you automate the publishing and
  collaboration process.
desc
end
