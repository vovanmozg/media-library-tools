# frozen_string_literal: true

require './lib/mover/commands'
require './lib/mover/commands/inside_new_doubtful'
require_relative 'comments'
require_relative 'handle_move'

class Mover
  class Linux
    class InsideNewDoubtful < Mover::Commands::InsideNewDoubtful
      include Mover::Linux::Comments
      include Mover::Linux::HandleMove
    end
  end
end
