require 'spec_helper'

module Codebreaker
  RSpec.describe ConsoleApp do
    subject(:app) { ConsoleApp.new }

    it 'initialize game field' do
      expect(app.instance_variable_get(:@game)).to be_an_instance_of(Game)
    end

    describe '#run' do
      before do
        allow(Messages).to receive(:puts)
        allow(app).to receive(:print)
        expect(app).to receive(:loop).and_yield
      end

      context 'when 0' do
        it 'exits' do
          expect(app).to receive(:gets).and_return('0')
          expect(Messages).to receive(:bye)
          app.run
        end
      end

      context 'when 1' do
        it 'calls #play' do
          expect(app).to receive(:gets).and_return('1')
          expect(app).to receive(:play)
          app.run
        end
      end

      context 'when 2' do
        it 'calls #high_scores' do
          expect(app).to receive(:gets).and_return('2')
          expect(app).to receive(:high_scores).and_return([])
          app.run
        end
      end

      context 'when else' do
        it 'outputs message about wrong option' do
          expect(app).to receive(:gets).and_return('else')
          expect(Messages).to receive(:wrong_option)
          app.run
        end
      end
    end

    describe '#check_guess' do
      it 'invokes #check_guess of @game and output its result' do
        expect(Messages).to receive(:tries_left)
          .with(app.instance_variable_get(:@game).tries_left)
        expect(app.instance_variable_get(:@game))
          .to receive(:check_guess).with('1234').and_return('+')
        expect { app.send(:check_guess, '1234') }.to output(/\+/).to_stdout
      end

      it 'outputs exception message when #check_guess of @game raises an error' do
        expect(app.instance_variable_get(:@game))
          .to receive(:check_guess).and_raise(ArgumentError, 'blabla')
        expect { app.send(:check_guess, '12345') }.to output(/blabla/).to_stdout
      end
    end

    describe '#save_score' do
      context 'when no' do
        it "doesn't call #save_score of @game" do
          allow(app).to receive(:print)
          allow(app).to receive_message_chain(:gets, :chomp).and_return('no')
          expect(app.instance_variable_get(:@game)).not_to receive(:save_score)
          app.send(:save_score)
        end
      end

      context 'when y' do
        it 'calls #save_score of @game' do
          allow(app).to receive(:print)
          allow(app).to receive(:puts)
          allow(app).to receive(:gets).and_return('y', 'Name')
          expect(app.instance_variable_get(:@game)).to receive(:save_score)
          app.send(:save_score)
        end
      end
    end

    describe '#high_scores' do
      context 'when scores empty' do
        it "returns 'No scores'" do
          expect(app.instance_variable_get(:@game)).to receive(:high_scores).and_return([])
          expect(app.send(:high_scores)).to eq('No scores')
        end
      end

      context 'when scores non empty' do
        it 'returns array of formatted players' do
          scores = Array.new(5) { |i| Player.new("Name#{i}", 5 - i, i % 3) }
          expect(app.instance_variable_get(:@game)).to receive(:high_scores).and_return(scores)
          expectation = app.send(:high_scores)
          expect(expectation).to be_an_instance_of(Array)
          expect(expectation.size).to eq(5 + 1)
          expect(expectation.first).to be_an_instance_of(String)
          expect(expectation.last).to eq(' 5 ' + scores.last.formatted)
        end
      end
    end

    describe '#play' do
      before do
        allow(Messages).to receive(:puts)
        allow(app).to receive(:print)
      end

      it 'saves score when game is won' do
        allow(app.instance_variable_get(:@game)).to receive(:answer)
        expect(app.instance_variable_get(:@game)).to receive(:finished?).and_return(true)
        expect(app.instance_variable_get(:@game)).to receive(:won?).and_return(true)
        expect(app).to receive(:save_score)
        app.send(:play)
      end

      context 'when 0' do
        it 'ends the game' do
          expect(app).to receive(:gets).and_return('0')
          expect(app.instance_variable_get(:@game)).not_to receive(:won?)
          app.send(:play)
        end
      end

      context 'when 1' do
        it 'outputs hint' do
          expect(app).to receive(:gets).and_return('1', '0')
          expect(app.instance_variable_get(:@game)).to receive(:hint)
          app.send(:play)
        end
      end
    end
  end
end
