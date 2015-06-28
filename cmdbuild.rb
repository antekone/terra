require 'optparse'
require 'ostruct'

require_relative 'config'
require_relative 'build'

class BuildCommand
  attr_reader(:name)
  def initialize
    @name = 'build'
  end

  def run(args)
    commands = OpenStruct.new
    commands.builders = []
    commands.help = false

    OptionParser.new do |opts|
      opts.on("-b", "--builder BUILDER", "Make builder BUILDER") do |bldname|
        commands.builders << bldname
      end

      opts.on("-h", "--help", "Help") do
        commands.help = true
      end
    end.parse(args)

    if commands.help == true
      puts("Build options:")
      puts("")
      puts("    -b BUILDER -- make builder BUILDER")
      return true
    end

    if commands.builders.length > 0
      results = commands.builders.map do |bldname|
        do_build(bldname)
      end

      puts("Build status:")
      results.each do |result|
        puts("-> #{result[:bldname]} build status: #{result[:status]}")
        if result[:status] == false
          return 1
        end
      end
    else
      puts("Nothing to do.")
      return 1
    end

    0
  end

  def do_build(bldname)
    build = Build.new(BUILDBOT_URL)
    if not build.init()
        return { :bldname => bldname, :status => false }
    end

    if build.get_activity(bldname) == 'building'
      puts("-> Already building #{bldname}.")
    else
      puts("-> Issuing build #{bldname}...")
      if false == build.force_build(bldname, 'build issued by Terra')
        return { :bldname => bldname, :status => false }
      end
    end

    loop do
      act = build.get_activity(bldname)
      break if act == 'building'
      sleep(3)
    end

    puts("Build running, waiting for completion...")
    finished_steps = []
    reported_steps = []

    loop do
      sleep(3)
      act = build.get_activity(bldname)

      binfo = build.get_builder_info(bldname)['currentBuilds']
      if binfo.length > 0
        binfo = build.get_build_id_info(bldname, binfo[0])
        print_binfo_steps(finished_steps, reported_steps, binfo)
      else
        # Everything was finished, get last 'cachedBuilds', and print everything as finished
        binfo = build.get_builder_info(bldname)['cachedBuilds']
        if binfo.length > 0 and act != 'building'
          binfo = build.get_build_id_info(bldname, binfo[-1])
          print_binfo_steps(finished_steps, reported_steps, binfo)
        end
      end

      break if act != 'building'
    end

    { :bldname => bldname, :status => true }
  end

  def print_binfo_steps(finished_steps, reported_steps, binfo)
    steps = binfo["steps"]
    steps.each_index do |i|
      step = steps[i]
      step_name = step["name"]
      step_text = if step["text"].length > 0
                    step["text"].join(" / ")
                  else
                    step["text"]
                  end
      step_finished = step["isFinished"]

      next if not step_finished
      next if reported_steps.index(i) != nil

      puts("    Step #{i + 1}/#{steps.length} finished: #{step_text} (#{step_name})")
      reported_steps << i
    end
  end
end

# vim: set tw=0 sw=2 ts=2:
