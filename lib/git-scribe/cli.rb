require 'subcommand'

class GitScribe
  include Subcommands

  def info(message)
    puts message
  end

  module CLI

    def run
      parse_options
      if @subcommand && self.respond_to?(@subcommand)
        begin
          self.send @subcommand, @args
        rescue Object => e
          error e
        end
      else
        help
      end
    end

    def error(e)
      puts 'Error: ' + e.to_s
    end

    def help
      puts print_actions
    end

    def parse_options
      @options = {}
      global_options do |opts|
        opts.banner = "Usage: #{$0} [options] [subcommand [options]]"
        opts.description = "git-scribe helps you write books with the power of Git"
        opts.separator ""
        opts.separator "Global options are:"
        opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
          @options[:verbose] = v
        end
      end

      command :init do |opts|
        opts.banner = "Usage: git scribe init (directory)"
        opts.description = "initialize a new book layout"
        opts.on("-l", "--lang", "choose a default language (en)") do |v|
          @options[:lang] = lang || 'en'
        end
      end

      command :gen do |opts|
        opts.banner = "Usage: git scribe gen [options]"
        opts.description = "generate digital formats: #{GitScribe::OUTPUT_TYPES.join('|')}"
      end

      command :check do |opts|
        opts.banner = "Usage: git scribe check"
        opts.description = "checks for system requirements for doc generation"
      end

      @subcommand = opt_parse
      @args = ARGV
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

  end

  include CLI
end
