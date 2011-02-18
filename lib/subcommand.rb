#!/usr/bin/env ruby -w
######################################
# A tiny wrapper over optparse that gives easy subcommand facility.
# It also neatly prints help for global and subcommands
# as well as summarizes subcommands in global help.
#
# Thanks to Robert Klemme for his idea on lazy loading the subcommand option parsers.
# 
# @author Rahul Kumar, Jun  2010
# @date 2010-06-20 22:33 
#
# @examples
# if a program has subcommands foo and baz
#
# ruby subcommand.rb help
# ruby subcommand.rb --help
# ruby subcommand.rb help foo
# ruby subcommand.rb foo --help
# ruby subcommand.rb baz --quiet "some text"
# ruby subcommand.rb --verbose foo --force file.zzz
#
# == STEPS 
#    1. define global_options (optional)
#
#     global_options do |opts|
#       opts.banner = "Usage: #{$0} [options] [subcommand [options]]"
#       opts.description = "Stupid program that does something"
#       opts.separator ""
#       opts.separator "Global options are:"
#       opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
#         options[:verbose] = v
#       end
#     end
#
#    2. define commands using command().
#     command :foo do |opts|
#       opts.banner = "Usage: foo [options]"
#       opts.description = "desc for foo"
#       opts.on("-f", "--[no-]force", "force verbosely") do |v|
#         options[:force] = v
#       end
#     end
#
#    3. call opt_parse()
#
#    4. As before, handle ARGS and options hash.
#
# TODO: add aliases for commands
######################################
require 'optparse'

# Allow command to have a description to generate help
class OptionParser
  attr_accessor :description
  #attr_accessor :action
end

module Subcommands
  ##
  # specify a single command and all its options
  # If multiple names are given, they are treated as aliases.
  # Do repeatedly for each command
  # Yields the optionparser
  def command *names
    name = names.shift
    @commands ||= {}
    @aliases ||= {}
    if names.length > 0
      names.each do |n| 
        #puts "aliases #{n} => #{name} "
        @aliases[n.to_s] = name.to_s
      end
    end
    # Thanks to Robert Klemme for the lazy loading idea.
    opt = lambda { OptionParser.new do |opts|
      yield opts
      # append desc to banner in next line
      opts.banner << "\n#{opts.description}\n" if opts.description
    end }
    @commands[name.to_s] = opt
  end
  # specify global options and banner and description
  # Yields the optionparser
  def global_options
    if !defined? @global
      @global = OptionParser.new do |opts|
        yield opts
      end
    else
      yield @global
    end
  end
  def print_actions
    cmdtext = "Commands are:"
    @commands.each_pair do |c, opt| 
      #puts "inside opt.call loop"
      desc = opt.call.description
      cmdtext << "\n   #{c} : #{desc}"
    end

    # print aliases
    unless @aliases.empty?
      cmdtext << "\n\nAliases: \n" 
      @aliases.each_pair { |name, val| cmdtext << "   #{name} - #{val}\n"  }
    end

    cmdtext << "\n\nSee '#{$0} help COMMAND' for more information on a specific command."
  end
  ## add text of subcommands in help and --help option
  def add_subcommand_help
    # user has defined some, but lets add subcommand information

    cmdtext = print_actions

    global_options do |opts|
      # lets add the description user gave into banner
      opts.banner << "\n#{opts.description}\n" if opts.description
      opts.separator ""
      opts.separator cmdtext
    end
  end
  # this is so that on pressing --help he gets same subcommand help as when doing help.
  # This is to be added in your main program, after defining global options
  # if you want detailed help on --help. This is since optionparser's default
  # --help will not print your actions/commands
  def add_help_option
    global_options do |opts|
      opts.on("-h", "--help", "Print this help") do |v|
        add_subcommand_help
        puts @global
        exit
      end
    end
  end
  # first parse global optinos
  # then parse subcommand options if valid subcommand
  # special case of "help command" so we print help of command - git style (3)
  # in all invalid cases print global help
  # @return command name if relevant
  def opt_parse
    # if user has not defined global, we need to create it
    @command_name = nil
    if !defined? @global
      global_options do |opts|
        opts.banner = "Usage: #{$0} [options] [subcommand [options]]"
        opts.separator ""
        opts.separator "Global options are:"
        opts.on("-h", "--help", "Print this help") do |v|
          add_subcommand_help
          puts @global
          exit
        end
        opts.separator ""
        #opts.separator subtext # FIXME: no such variable supposed to have subcommand help
      end
    else
    end
    @global.order!
    cmd = ARGV.shift
    if cmd
      #$stderr.puts "Command: #{cmd}, args:#{ARGV}, #{@commands.keys} "
      sc = @commands[cmd] 
      #puts "sc: #{sc}: #{@commands}"
      unless sc
        # see if an alias exists
        sc, cmd = _check_alias cmd
      end
      # if valid command parse the args
      if sc
        @command_name = cmd
        sc.call.order!
      else
        # else if help <command> then print its help GIT style (3)
        if !ARGV.empty? && cmd == "help"
          cmd = ARGV.shift
          #$stderr.puts " 110 help #{cmd}"
          sc = @commands[cmd]
          # if valid command print help, else print global help
          unless sc
            sc, cmd = _check_alias cmd
          end
          if sc
            #puts " 111 help #{cmd}"
            puts sc.call
          else 
            # no help for this command XXX check for alias
            puts "Invalid command: #{cmd}."
            add_subcommand_help
            puts @global
          end
        else
          # invalid command 
          puts "Invalid command: #{cmd}" unless cmd == "help"
          add_subcommand_help
          puts @global 
        end
        exit 0
      end
    end
    return @command_name
  end
  def alias_command name, *args
    @aliases[name.to_s] = args
  end
  def _check_alias cmd
    alas = @aliases[cmd]
    #$stderr.puts "195 alas: #{alas} "
    if alas
      case alas
      when Array
        cmd = alas.shift
        #$stderr.puts "Array cmd: #{cmd} "
        ARGV.unshift alas.shift unless alas.empty?
        #$stderr.puts "ARGV  #{ARGV} "
      else
        cmd = alas
      end
    end
    sc = @commands[cmd] if cmd
    return sc, cmd
  end
end

if __FILE__ == $PROGRAM_NAME
  include Subcommands
  options = {}
  appname = File.basename($0)
  # global is optional
  global_options do |opts|
    opts.banner = "Usage: #{appname} [options] [subcommand [options]]"
    opts.description = "Stupid program that does something"
    opts.separator ""
    opts.separator "Global options are:"
    opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
      options[:verbose] = v
    end
  end
  add_help_option
  # define a command
  command :foo, :goo do |opts|
    opts.banner = "Usage: foo [options]"
    opts.description = "desc for foo"
    opts.on("-f", "--[no-]force", "force verbosely") do |v|
      options[:force] = v
    end
  end
  command :baz do |opts|
    opts.banner = "Usage: baz [options]"
    opts.description = "desc for baz"
    opts.on("-q", "--[no-]quiet", "quietly run ") do |v|
      options[:quiet] = v
    end
  end
  alias_command :bar, 'baz'
  alias_command :boo, 'foo', '--force'
  alias_command :zoo, 'foo', 'ruby'

  # do the parsing.
  cmd = opt_parse()

  puts "cmd: #{cmd}"
  puts "options ......"
  p options
  puts "ARGV:"
  p ARGV
end
