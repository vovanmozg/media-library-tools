# frozen_string_literal: true

require_relative 'base_command'

class Mover
  class Commands
    class InsideNewFullDups < BaseCommand
      def header_title
        'Identical files inside new dir'
      end
    end
  end
end
