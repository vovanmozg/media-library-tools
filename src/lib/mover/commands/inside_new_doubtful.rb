# frozen_string_literal: true
#
require_relative 'base_command'

class Mover
  class Commands
    class InsideNewDoubtful < BaseCommand
      def header_title
        'Doubtful similar files inside new dir'
      end
    end
  end
end
