require 'thor'

module Capacitor
  class CLI < Thor
    include Thor::Actions

    desc 'start', 'Run the capacitor'

    def start
      Capacitor.run
    end
  end
end
