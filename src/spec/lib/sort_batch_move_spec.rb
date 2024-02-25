# frozen_string_literal: true

require 'spec_helper'
require './lib/sort_batch_move'

describe SortBatchMove do
  let(:config) do
    {
      new_dir_path: "#{@root}/new",
      existing_dir_path: "#{@root}/existing",
      dups_dir_path: "#{@root}/dups",
      data_dir_path: "#{@root}/data"
    }.freeze
  end

  let(:moving_actions) { { "#{@root}/new/тест/1.jpg" => 'foto' } }

  it 'returns error that file does not exist' do
    result = described_class.new.call(moving_actions, config)
    expect(result).to eq(["File does not exist: #{@root}/new/тест/1.jpg, destination:#{@root}/data/foto/тест/1.jpg<br>"])
  end


  context 'when file exists' do
    before do
      FileUtils.mkdir_p("#{@root}/new/тест")
      FileUtils.cp('./spec/fixtures/media/1.jpg', "#{@root}/new/тест/1.jpg")
    end

    context 'when foto' do
      it 'moves files' do
        result = described_class.new.call(moving_actions, config)
        expect(result).to eq(["Moved (foto): #{@root}/new/тест/1.jpg to #{@root}/data/foto/тест/1.jpg<br>"])
      end
    end
  end
end
