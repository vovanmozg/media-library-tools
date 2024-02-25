# frozen_string_literal: true

require './spec/spec_helper'
require './lib/mover'

describe Mover do
  let(:data_dir) { "#{@root}/data" }

  before do
    FileUtils.mkdir_p(data_dir)
  end

  it 'converts inside_new_similar_doubtful' do
    actions = jf('./spec/fixtures/mover/linux/inside_new_doubtful/operations.json')
    settings = {
      new_dir: '/new',
      dups_dir: '/dups',
      real_new_dir: '/real/new',
      real_dups_dir: '/real/dups',
      data_dir:,
      driver_type: :linux
    }
    cmds = described_class.new(settings:).call(operations: actions)
    expected = jf('./spec/fixtures/mover/linux/inside_new_doubtful/cmds.json')
    expect(cmds).to match_array(expected)
  end

  it 'converts inside_new_full_dups' do
    actions = jf('./spec/fixtures/mover/linux/inside_new_full_dups/operations.json')
    cmds = described_class.new(settings: { data_dir:, driver_type: :linux }).call(operations: actions)
    expected = jf('./spec/fixtures/mover/linux/inside_new_full_dups/cmds.json')
    expect(cmds).to match_array(expected)
  end

  it 'converts inside_new_similar' do
    actions = jf('./spec/fixtures/mover/linux/inside_new_similar/operations.json')
    cmds = described_class.new(settings: { data_dir:, driver_type: :linux }).call(operations: actions)
    expected = jf('./spec/fixtures/mover/linux/inside_new_similar/cmds.json')
    expect(cmds).to match_array(expected)
  end

  it 'converts full_dups' do
    actions = jf('./spec/fixtures/mover/linux/full_dups/operations.json')
    settings = {
      new_dir: '/vt/new',
      real_new_dir: '/vt/new',
      existing_dir: '/vt/existing',
      real_existing_dir: '/vt/existing',
      dups_dir: '/vt/dups',
      real_dups_dir: '/vt/dups',
      data_dir:,
      driver_type: :linux
    }
    cmds = described_class.new(settings:).call(operations: actions)
    expected = jf('./spec/fixtures/mover/linux/full_dups/cmds.json')
    expect(cmds).to match_array(expected)
  end

  it 'converts similar' do
    actions = jf('./spec/fixtures/mover/linux/similar/operations.json')
    cmds = described_class.new(settings: { data_dir:, driver_type: :linux }).call(operations: actions)
    expected = jf('./spec/fixtures/mover/linux/similar/cmds.json')
    expect(cmds).to match_array(expected)
  end
end
