require 'spec_helper'

module Codebreaker
  RSpec.describe Game do
    subject(:game) { Game.new }
    before { game.start	}

    it { is_expected.to respond_to(:tries_left) }

    it { is_expected.not_to respond_to(:tries_left=) }

    describe '#start' do
      let(:code) { game.instance_variable_get(:@code) }

      it 'generates a secret code with 4 numbers from 1 to 6' do
        expect(code).not_to be_empty
        expect(code.size).to eq(4)
        expect(code).to match(/^[1-6]+/)
      end

      it 'generates a different secret code each time' do
        code1 = game.instance_variable_get(:@code)
        game.start
        code2 = game.instance_variable_get(:@code)
        expect(code1).not_to eq(code2)
      end
    end

    describe '#check_guess' do
      it 'raises an error with an invalid input' do
        test_data = ['0123', '1237', '123', '12345', 'string', 5]

        test_data.each do |input|
          expect { game.check_guess(input) }.to raise_error(ArgumentError)
        end
      end

      it 'returns right results' do
        game.instance_variable_set(:@code, '2131')

        test_data    = %w[1111 2222 3333 4444 5555 6666
                          1312 1216 1616 1666 1234 2131]
        expectations = ['++', '+', '+', '', '', '',
                        '----', '---', '--', '-', '+--', '++++']

        test_data.each_index do |i|
          expect(game.check_guess(test_data[i])).to eq(expectations[i])
        end
      end

      it 'returns right result' do
        game.instance_variable_set(:@code, '4422')
        expect(game.check_guess('3456')).to eq('+')
      end

      it 'uses check_guess method' do
        code = game.instance_variable_get(:@code)
        input = '1111'
        expect(game).to receive(:check_input).with(code.chars, input.chars)
        game.check_guess(input)
      end

      it 'decreases number of tries_left by 1' do
        expect { game.check_guess('1111') }.to change { game.tries_left }.by(-1)
      end

      it 'uses check guess method' do
        code = game.instance_variable_get(:@code)
        input = '1111'
        expect(game).to receive(:check_input).with(code.chars, input.chars)
        game.check_guess(input)
      end

      it 'uses define_stage method' do
        allow(game).to receive(:check_input).and_return('++-')
        expect(game).to receive(:define_stage).with('++-')
        game.check_guess('1111')
      end
    end

    describe '#hint' do
      it 'decreases number of tries_left and hints_left by 1' do
        expect { game.hint }.to change { game.tries_left }.by(-1)
        expect { game.hint }.to change { game.hints_left }.by(-1)
      end

      it 'uses define_stage method' do
        expect(game).to receive(:define_stage).with(no_args)
        game.hint
      end

      it 'returns false when no hints left' do
        game.instance_variable_set(:@hints_left, 0)
        expect(game.hint).to be false
      end

      it 'returns a digit from secret code when hints left' do
        code = game.instance_variable_get(:@code)
        regexp = Regexp.new("[#{code.chars.join('|')}]{1}")
        expect(game.hint).to match(regexp)
      end

      it 'shortens the array of indexes by 1' do
        expect { game.hint }
          .to change { game.instance_variable_get(:@indexes_for_hint).length }
          .by(-1)
      end
    end

    describe '#define_stage' do
      context 'with ordinary result' do
        it "doesn't change finished field" do
          expect { game.send(:define_stage, '+-') }
            .not_to change { game.instance_variable_get(:@finished) }
        end

        it "doesn't change won field" do
          expect { game.send(:define_stage, '+-') }
            .not_to change { game.instance_variable_get(:@won) }
        end

        context 'when no tries left' do
          before { game.instance_variable_set(:@tries_left, 0) }

          it 'changes finished field' do
            expect { game.send(:define_stage, '+-') }
              .to change { game.instance_variable_get(:@finished) }.from(false).to(true)
          end

          it "doesn't change won field" do
            expect { game.send(:define_stage, '+-') }
              .not_to change { game.instance_variable_get(:@won) }
          end
        end
      end

      context 'with ++++ result' do
        it 'changes finished field' do
          expect { game.send(:define_stage, '++++') }
            .to change { game.instance_variable_get(:@finished) }.from(false).to(true)
        end

        it 'changes won field' do
          expect { game.send(:define_stage, '++++') }
            .to change { game.instance_variable_get(:@won) }.from(false).to(true)
        end
      end
    end

    describe '#process_file' do
      let(:file_data) { game.send(:process_file, 'scores.yml') }
      after { File.delete('scores.yml') if File.exist?('scores.yml') }

      it "returns empty array if file doesn't exist" do
        expect(file_data).to be_an_instance_of(Array)
        expect(file_data).to be_empty
      end

      it 'returns empty array if file empty' do
        File.open('scores.yml', 'w') {}
        expect(file_data).to be_an_instance_of(Array)
        expect(file_data).to be_empty
      end

      it 'returns array of players' do
        player = Player.new('Name', 5, 2)
        File.open('scores.yml', 'w') { |f| f.write [player].to_yaml }
        expect(file_data).to be_an_instance_of(Array)
        expect(file_data.first).to be_an_instance_of(Player)
      end
    end

    describe '#high_scores' do
      it 'uses #process_file' do
        expect(game).to receive(:process_file).with('scores.yml')
        game.high_scores('scores.yml')
      end
    end

    describe '#save_score' do
      after { File.delete('scores.yml') if File.exist?('scores.yml') }

      it 'uses #process_file' do
        expect(game).to receive(:process_file).with('scores.yml').and_return([])
        game.save_score('Name')
      end

      it 'adds player to scores' do
        expect { game.save_score('Name') }
          .to change { game.send(:process_file, 'scores.yml').size }.by(1)
        expect(game.send(:process_file, 'scores.yml').last).to be_an_instance_of(Player)
      end

      it 'adds no more than 10 players to scores' do
        11.times { |i| game.save_score("Name#{i}") }
        expect(game.send(:process_file, 'scores.yml').size).to be_eql(10)
      end
    end

    describe '#check_input' do
      let(:test_data) {
        [
          ['1234', '1234', '++++'],
          ['1234', '4321', '----'],
          ['1231', '1234', '+++'],
          ['1134', '1431', '++--'],
          ['1324', '1234', '++--'],
          ['1111', '1321', '++'],
          ['1234', '1111', '+'],
          ['2552', '1221', '--'],
          ['1234', '2332', '+-'],
          ['4441', '2233', ''],
          ['1234', '5561', '-'],
          ['1234', '1342', '+---'],
          ['3211', '1561', '+-'],
          ['1666', '6661', '++--'],
          ['1134', '1155', '++'],
          ['1134', '5115', '+-'],
          ['1134', '5511', '--'],
          ['1134', '1115', '++'],
          ['1134', '5111', '+-'],
          ['1234', '1555', '+'],
          ['1234', '2555', '-'],
          ['1234', '5224', '++'],
          ['1234', '5154', '+-'],
          ['1234', '2545', '--'],
          ['1234', '5234', '+++'],
          ['1234', '5134', '++-'],
          ['1234', '5124', '+--'],
          ['1234', '5115', '-'],
          ['1234', '1234', '++++'],
          ['5143', '4153', '++--'],
          ['5523', '5155', '+-'],
          ['6235', '2365', '+---'],
          ['1234', '4321', '----'],
          ['1234', '1235', '+++'],
          ['1234', '6254', '++'],
          ['1234', '5635', '+'],
          ['1234', '4326', '---'],
          ['1234', '3525', '--'],
          ['1234', '2552', '-'],
          ['1234', '4255', '+-'],
          ['1234', '1524', '++-'],
          ['1234', '5431', '+--'],
          ['1234', '6666', ''],
          ['1115', '1231', '+-'],
          ['1231', '1111', '++'],
          ['1111', '1111', '++++'],
          ['1111', '1115', '+++'],
          ['1111', '1155', '++'],
          ['1111', '1555', '+'],
          ['1111', '5555', ''],
          ['1221', '2112', '----'],
          ['1221', '2114', '---'],
          ['1221', '2155', '--'],
          ['1221', '2555', '-'],
          ['2245', '2254', '++--'],
          ['2245', '2253', '++-'],
          ['2245', '2435', '++-'],
          ['2245', '2533', '+-'],
          ['1234', '4321', '----'],
          ['3331', '3332', '+++'],
          ['1113', '1112', '+++'],
          ['1312', '1212', '+++'],
          ['1234', '1266', '++'],
          ['1234', '6634', '++'],
          ['1234', '1654', '++'],
          ['1234', '1555', '+'],
          ['1234', '4321', '----'],
          ['5432', '2345', '----'],
          ['1234', '2143', '----'],
          ['1221', '2112', '----'],
          ['5432', '2541', '---'],
          ['1145', '6514', '---'],
          ['1244', '4156', '--'],
          ['1221', '2332', '--'],
          ['2244', '4526', '--'],
          ['5556', '1115', '-'],
          ['1234', '6653', '-'],
          ['3331', '1253', '--'],
          ['2345', '4542', '+--'],
          ['1243', '1234', '++--'],
          ['4111', '4444', '+'],
          ['1532', '5132', '++--'],
          ['3444', '4334', '+--'],
          ['1113', '2155', '+'],
          ['2245', '4125', '+--'],
          ['4611', '1466', '---'],
          ['5451', '4445', '+-'],
          ['6541', '6541', '++++'],
          ['1234', '5612', '--'],
          ['5566', '5600', '+-'],
          ['6235', '2365', '+---'],
          ['1234', '4321', '----'],
          ['1234', '1235', '+++'],
          ['1234', '6254', '++'],
          ['1234', '5635', '+'],
          ['1234', '4326', '---'],
          ['1234', '3525', '--'],
          ['1234', '2552', '-'],
          ['1234', '4255', '+-'],
          ['1234', '1524', '++-'],
          ['1234', '5431', '+--'],
          ['1234', '6666', ''],
          ['1115', '1231', '+-'],
          ['1221', '2112', '----'],
          ['1231', '1111', '++'],
          %w[1234 1234 ++++],
          %w[4444 4444 ++++],
          %w[3331 3332 +++],
          %w[1113 1112 +++],
          %w[1234 1266 ++],
          %w[1234 6634 ++],
          %w[1234 1654 ++],
          %w[1234 1555 +],
          %w[1234 4321 ----],
          %w[5432 2345 ----],
          %w[1234 2143 ----],
          %w[1221 2112 ----],
          %w[5432 2541 ---],
          %w[1145 6514 ---],
          %w[1244 4156 --],
          %w[1221 2332 --],
          %w[2244 4526 --],
          %w[5556 1115 -],
          %w[1234 6653 -],
          %w[3331 1253 --],
          %w[1243 1234 ++--],
          %w[4111 4444 +],
          %w[1532 5132 ++--],
          %w[3444 4334 +--],
          %w[1113 2155 +],
          %w[2245 4125 +--],
          %w[4611 1466 ---],
          ['3331', '3332', '+++'],
          ['1113', '1112', '+++'],
          ['1312', '1212', '+++'],
          ['1234', '1235', '+++'],
          ['1234', '1266', '++'],
          ['1122', '1325', '++'],
          ['1234', '6634', '++'],
          ['1234', '1654', '++'],
          ['1243', '1234', '++--'],
          ['1532', '5132', '++--'],
          ['1234', '1324', '++--'],
          ['1234', '1243', '++--'],
          ['1234', '1245', '++-'],
          ['1234', '1524', '++-'],
          ['1234', '5231', '++-'],
          ['1234', '6134', '++-'],
          ['1234', '1423', '+---'],
          ['1234', '4213', '+---'],
          ['1234', '2431', '+---'],
          ['1234', '2314', '+---'],
          ['2112', '1222', '+--'],
          ['2345', '4542', '+--'],
          ['3444', '4334', '+--'],
          ['2245', '4125', '+--'],
          ['5451', '4445', '+-'],
          ['1234', '5212', '+-'],
          ['1234', '1112', '+-'],
          ['1122', '1233', '+-'],
          ['1234', '1555', '+'],
          ['1234', '1111', '+'],
          ['4111', '4444', '+'],
          ['1113', '2155', '+'],
          ['5556', '1115', '-'],
          ['1234', '6653', '-'],
          ['1234', '5551', '-'],
          ['1234', '5511', '-'],
          ['1244', '4156', '--'],
          ['1221', '2332', '--'],
          ['3331', '1253', '--'],
          ['2244', '4526', '--'],
          ['5432', '2541', '---'],
          ['1145', '6514', '---'],
          ['4611', '1466', '---'],
          ['1234', '6423', '---'],
          ['1234', '4321', '----'],
          ['5432', '2345', '----'],
          ['1234', '2143', '----'],
          ['1221', '2112', '----'],
          ['1234', '5555', ''],
          ['1234', '5656', ''],
          ['1234', '6655', ''],
          ['1234', '5665', ''],
          ['1111', '2222', ''],
          ['1211', '3333', ''],
          ['1121', '3333', ''],
          ['1112', '3333', ''],
          ['1112', '4444', ''],
          ['1212', '3456', ''],
          ['3334', '3331', '+++'],
          ['3433', '3133', '+++'],
          ['3343', '3313', '+++'],
          ['4333', '1333', '+++'],
          ['4332', '1332', '+++'],
          ['4323', '1323', '+++'],
          ['4233', '1233', '+++'],
          ['2345', '2346', '+++'],
          ['2534', '2634', '+++'],
          ['2354', '2364', '+++'],
          ['1234', '5123', '---'],
          ['3612', '1523', '---'],
          ['3612', '2531', '---'],
          ['1234', '5612', '--'],
          ['1234', '5621', '--'],
          ['4321', '1234', '----'],
          ['3421', '1234', '----'],
          ['3412', '1234', '----'],
          ['4312', '1234', '----'],
          ['1423', '1234', '+---'],
          ['1342', '1234', '+---'],
          ['5255', '2555', '++--'],
          ['5525', '2555', '++--'],
          ['5552', '2555', '++--'],
          ['6262', '2626', '----'],
          ['6622', '2626', '++--'],
          ['2266', '2626', '++--'],
          ['2662', '2626', '++--'],
          ['6226', '2626', '++--'],
          ['3135', '3315', '++--'],
          ['3513', '3315', '++--'],
          ['3351', '3315', '++--'],
          ['1353', '3315', '+---'],
          ['5313', '3315', '++--'],
          ['1533', '3315', '----'],
          ['5331', '3315', '+---'],
          ['5133', '3315', '----'],
          ['3361', '3315', '++-'],
          ['3136', '3635', '++-'],
          ['1336', '6334', '++-'],
          ['1363', '6323', '++-'],
          ['1633', '6233', '++-'],
          ['1234', '4343', '--']
        ]
      }

      it 'returns right results' do
        test_data.each do |test|
          # puts test
          expect(game.send(:check_input, test[0].chars, test[1].chars)).to eq(test[2])
        end
      end
    end
  end
end
