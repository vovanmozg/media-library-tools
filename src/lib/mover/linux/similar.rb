require './lib/mover/commands'
require './lib/mover/commands/similar'
require_relative 'comments'

class Mover
  class Linux
    class Similar < Mover::Commands::Similar
      include Mover::Linux::Comments
      include Mover::Linux::HandleMove
    end
  end
end
