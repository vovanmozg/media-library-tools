require './lib/mover/commands'
require './lib/mover/commands/full_dups'
require_relative 'comments'

class Mover
  class Linux
    class FullDups < Mover::Commands::FullDups
      include Mover::Linux::Comments
      include Mover::Linux::HandleMove
    end
  end
end
