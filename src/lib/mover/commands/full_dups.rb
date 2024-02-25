# frozen_string_literal: true

require_relative 'base_command'

class Mover
  class Commands
    class FullDups < BaseCommand
      def header_title
        'Files in new identical to existing'
      end
    end
  end
end
