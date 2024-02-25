# frozen_string_literal: true

class Mover
  class Commands
    class BaseCommand
      def header
        Mover::Commands.new.header(comment, header_title)
      end
    end
  end
end
