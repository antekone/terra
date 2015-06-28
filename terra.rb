require 'optparse'

require_relative 'build'
require_relative 'cmdlist'
require_relative 'cmdbuild'

def wait_for_idle(build, builders)
  puts("Waiting for idle...")
  loop do
    idles = 0
    builders.each do |b|
      act = build.get_activity(b)
      if act == 'idle' or act == 'offline'
        idles += 1
      end
    end

    return true if idles == builders.size
    sleep(5)
  end
end

def main
  puts("Terra -- product build terraformation tool v0.2")
  puts("")

  options = {}
  commands = [
    ListCommand.new,
    BuildCommand.new
  ]

  if ARGV.length == 0
    puts("Please use `-h` for help.")
    exit(1)
  end

  if ARGV[0] == "-h"
    puts("Available commands: #{commands.map { |cmd| cmd.name }.join(", ") }")
    exit(0)
  end

  commands.each do |cmd|
    if cmd.name == ARGV[0]
      ret = cmd.run(ARGV[1..-1])

      if ret.is_a? Integer and ret > 0
        puts("")
        puts("Command #{cmd.name} failed with status #{ret}.")
      elsif ret.is_a? FalseClass
        puts("")
        puts("Command #{cmd.name} failed.")
      end

      exit(ret)
    end
  end
end

main

# vim: set ts=2 sw=2:
