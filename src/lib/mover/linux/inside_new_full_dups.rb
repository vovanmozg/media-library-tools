# frozen_string_literal: true

require './lib/mover/commands'
require './lib/mover/commands/inside_new_full_dups'
require_relative 'comments'

class Mover
  class Linux
    class InsideNewFullDups < Mover::Commands::InsideNewFullDups
      include Mover::Linux::Comments
      include Mover::Linux::HandleMove
    end
  end
end
