# frozen_string_literal: true

require './lib/mover/commands'
require './lib/mover/commands/inside_new_similar'
require_relative 'comments'

class Mover
  class Linux
    class InsideNewSimilar < Mover::Commands::InsideNewSimilar
      include Mover::Linux::Comments
      include Mover::Linux::HandleMove
    end
  end
end
