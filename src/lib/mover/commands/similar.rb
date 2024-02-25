# frozen_string_literal: true

require_relative 'base_command'

class Mover
  class Commands
    class Similar < BaseCommand
      def header_title
        'Files in new similar to existing'
      end
    end
  end
end
