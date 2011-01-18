require 'pp'

class GitScribe

  def initialize(args)
    @command = args.shift
    @args = args
  end

  def self.start(args)
    GitScribe.new(args).run
  end

  def run
    if @command && self.respond_to?(@command)
      self.send @command
    else
      help
    end
  end

  ## COMMANDS ##
 
  def help
    puts "No command: #{@command}"
    puts "TODO: tons of help"
  end

  # DISPLAY HELPER FUNCTIONS #

  def l(info, size)
    clean(info)[0, size].ljust(size)
  end

  def r(info, size)
    clean(info)[0, size].rjust(size)
  end

  def clean(info)
    info.to_s.gsub("\n", ' ')
  end

  # API/DATA HELPER FUNCTIONS #

  def git(command)
    `git #{command}`.chomp
  end
end
