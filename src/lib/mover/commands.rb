# frozen_string_literal: true

class Mover
  class Commands
    def header(comment, title)
      [
        "#{comment} #{'#' * (title.length + 4)}",
        "#{comment} # #{title} #",
        "#{comment} #{'#' * (title.length + 4)}"
      ]
    end
  end
end
