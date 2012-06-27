class GitScribe
  module Init
    # start a new scribe directory with skeleton structure
    def init(args = [])
      name = first_arg(args)
      die("needs a directory name") if !name
      die("directory already exists") if File.exists?(name)

      info "inititalizing #{name}"
      from_stdir = File.join(SCRIBE_ROOT, 'template')
      target_path = File.expand_path(name)
      ign = Dir.glob(from_stdir + '/.[a-z]*')
      FileUtils.cp_r from_stdir, name
      FileUtils.cp_r ign, name
      Grit::Repo.init(target_path)
    end
  end
end
