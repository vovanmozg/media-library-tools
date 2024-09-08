require 'sucker_punch'

class PhashWorker
  include SuckerPunch::Job

  def perform(file_name)
    @media = Media.new
    @media.read_file!(file_name:)
  end
end
