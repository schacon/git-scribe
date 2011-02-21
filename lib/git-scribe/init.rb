class GitScribe
  module Init
    # start a new scribe directory with skeleton structure
    def init(args = [])
      name = first_arg(args)
      die("needs a directory name") if !name
      die("directory already exists") if File.exists?(name)

      info "inititalizing #{name}"
      from_stdir = File.join(SCRIBE_ROOT, 'template')
      FileUtils.cp_r from_stdir, name
    end
  end
end
