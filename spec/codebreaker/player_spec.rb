require 'spec_helper'

module Codebreaker
  RSpec.describe Player do
    subject(:player) { Player.new('Name', 5, 2) }

    it { is_expected.not_to respond_to(:name=) }

    it 'has name, tries_left and hints_left fields' do
      expect(player.instance_variable_get(:@name)).to be
      expect(player.instance_variable_get(:@tries_left)).to be
      expect(player.instance_variable_get(:@hints_left)).to be
    end

    describe '.new' do
      it "constructs object with right fields' values" do
        expect(player.instance_variable_get(:@name)).to eq('Name')
        expect(player.instance_variable_get(:@tries_left)).to eq(5)
        expect(player.instance_variable_get(:@hints_left)).to eq(2)
      end

      it 'raises an error if we try to create object with long name' do
        expect { Player.new('NameNameName', 5, 2) }.to raise_error(ArgumentError)
      end

      it 'raises an error if we try to create object with empty name' do
        expect { Player.new('', 5, 2) }.to raise_error(ArgumentError)
      end
    end

    describe '#formatted' do
      it 'returns formatted player info' do
        expect(player.formatted).to eq('      Name    750')
      end
    end
  end
end
