# frozen_string_literal: true

require_relative 'base_command'

class Mover
  class Commands
    class InsideNewSimilar < BaseCommand
      def header_title
        'Similar files inside new dir'
      end
    end
  end
end
