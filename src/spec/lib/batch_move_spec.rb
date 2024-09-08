# frozen_string_literal: true

require 'spec_helper'
require './lib/batch_move'

describe BatchMove do
  let(:config) do
    {
      new_dir_path: "#{@root}/new",
      existing_dir_path: "#{@root}/existing",
      dups_dir_path: "#{@root}/dups",
      data_dir_path: "#{@root}/data"
    }.freeze
  end

  let(:data) do
    {
      'inside_new_full_dups' => [
        {
          'type' => 'move',
          'from' => {
            'type' => 'image',
            'phash' => 17_980_308_530_390_437_417,
            'width' => 1280,
            'height' => 835,
            'mtime' => 1_653_685_214,
            'md5' => '9ee4ef18e92784a6eb7379875158b6c7',
            'size' => 192_453,
            'name' => 'dup.jpg',
            'id' => '1653685214 192453 dup.jpg',
            'full_path' => "#{@root}/new/wai/dup.jpg"
          },
          'to' => "#{@root}/dups/new_inside_full_dups/wai/original.jpg",
          'original' => {
            'type' => 'image',
            'phash' => 17_980_308_530_390_437_417,
            'width' => 1280,
            'height' => 835,
            'mtime' => 1_653_685_214,
            'md5' => '9ee4ef18e92784a6eb7379875158b6c7',
            'size' => 192_453,
            'name' => 'original.jpg',
            'id' => '1653685214 192453 original.jpg',
            'full_path' => "#{@root}/new/wai/original.jpg",
            'real_path' => '/home/vp/Pictures/pocox3-2023-08-30/in/wai/original.jpg',
            'date' => '2022-05-27 21 =>00 =>14',
            'ratio' => 1.5
          },
          'dup' => {
            'distance' => 0,
            'date' => '2022-05-27 21 =>00 =>14',
            'ratio' => 1.5,
            'real_path' => '/home/vp/Pictures/pocox3-2023-08-30/dups/new_inside_full_dups/wai/original.jpg'
          }
        }
      ]
    }
  end

  let(:moving_actions) { {"#{@root}/dups/new_inside_full_dups/wai/original.jpg" => 'orig-remove-dup-skip'} }

  it 'returns error that file does not exist' do
    result = described_class.new.call(moving_actions, data, config)
    expect(result).to eq(["File does not exist: #{@root}/new/wai/original.jpg, destination:#{@root}/data/removed/wai/original.jpg<br>"])
  end

  # it 'moves files' do
  #   FileUtils.mkdir_p("#{@root}/new/wai")
  #   FileUtils.cp('./spec/fixtures/media/1.jpg', "#{@root}/new/wai/original.jpg")
  #   result = described_class.new.call(moving_actions, data, config)
  #   expect(result).to eq(["Moved original: #{@root}/new/wai/original.jpg to #{@root}/data/removed/wai/original.jpg<br>"])
  # end

  context 'when file exists' do
    before do
      FileUtils.mkdir_p("#{@root}/new/wai")
      FileUtils.cp('./spec/fixtures/media/1.jpg', "#{@root}/new/wai/original.jpg")
      FileUtils.cp('./spec/fixtures/media/1.jpg', "#{@root}/new/wai/dup.jpg")
    end

    context 'when orig-remove-dup-skip' do
      it 'moves files' do
        result = described_class.new.call(moving_actions, data, config)
        expect(result).to eq(["Moved original: #{@root}/new/wai/original.jpg to #{@root}/data/removed/wai/original.jpg<br>"])
      end
    end

    context 'when remove-dup' do
      let(:moving_actions) { {"#{@root}/dups/new_inside_full_dups/wai/original.jpg" => 'orig-skip-dup-remove'} }

      it 'moves files' do
        result = described_class.new.call(moving_actions, data, config)
        expect(result).to eq(["Moved dup: #{@root}/new/wai/dup.jpg to #{@root}/data/removed/wai/dup.jpg<br>"])
      end
    end

    context 'when remove-both' do
      let(:moving_actions) { {"#{@root}/dups/new_inside_full_dups/wai/original.jpg" => 'orig-remove-dup-remove'} }

      it 'moves files' do
        result = described_class.new.call(moving_actions, data, config)
        expected = [
          "Moved original: #{@root}/new/wai/original.jpg to #{@root}/data/removed/wai/original.jpg<br>",
          "Moved dup: #{@root}/new/wai/dup.jpg to #{@root}/data/removed/wai/dup.jpg<br>"
        ]
        expect(result).to eq(expected)
      end
    end

    context 'when archive-both' do
      let(:moving_actions) { {"#{@root}/dups/new_inside_full_dups/wai/original.jpg" => 'orig-archive-dup-remove'} }

      it 'moves files' do
        result = described_class.new.call(moving_actions, data, config)
        expected = [
          "Moved original: #{@root}/new/wai/original.jpg to #{@root}/data/archive/wai/original.jpg<br>",
          "Moved dup: #{@root}/new/wai/dup.jpg to #{@root}/data/removed/wai/dup.jpg<br>"
        ]
        expect(result).to eq(expected)
      end
    end

    context 'when orig-nofoto-dup-remove' do
      let(:moving_actions) { {"#{@root}/dups/new_inside_full_dups/wai/original.jpg" => 'orig-nofoto-dup-remove'} }

      it 'moves files' do
        result = described_class.new.call(moving_actions, data, config)
        expected = [
          "Moved original: #{@root}/new/wai/original.jpg to #{@root}/data/new-nofoto/wai/original.jpg<br>",
          "Moved dup: #{@root}/new/wai/dup.jpg to #{@root}/data/removed/wai/dup.jpg<br>"
        ]
        expect(result).to eq(expected)
      end
    end
  end
end
