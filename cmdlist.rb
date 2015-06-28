require 'optparse'

require_relative 'config'
require_relative 'build'

class ListCommand
  attr_reader(:name)

  def initialize()
    @name = "list"
  end

  def run(args)
    # No options for 'list' yet.
    build = Build.new(BUILDBOT_URL)
    build.init()
    builders = build.get_builders()

    if builders.length == 0
      puts("Error: no builders defined, or buildbot not running.")
      return 1
    end

    print_list(build.get_activities())
    builders.length > 0
  end

  def print_list(lst)
    lst.each do |bldname,blddata|
      puts("- %-30s #{blddata['state']}" % bldname)
    end
  end
end

# vim: set sw=2 tw=0 ts=2:
