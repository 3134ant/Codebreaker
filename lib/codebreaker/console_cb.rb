require_relative 'message'

module Codebreaker
  class ConsoleApp
    def initialize
      @game = Game.new
    end

    def run
      Messages.logo
      Messages.welcome

      loop do
        Messages.run
        print '> '

        case gets.chomp
        when '1' then play
        when '2' then puts high_scores
        when '0'
          Messages.bye
          break
        else Messages.wrong_option
        end
      end
    end

    private

    def play
      @game.start
      Messages.play

      until @game.finished?
        print '>>> '
        input = gets.chomp

        case input
        when '1' then Messages.hint(@game.hint, @game.hints_left, @game.tries_left)
        when '0' then return
        else check_guess(input)
        end
      end

      if @game.won?
        Messages.win(@game.answer)
        save_score
      else
        Messages.lose(@game.answer)
      end
    end

    def high_scores
      scores = @game.high_scores

      return 'No scores' if scores.empty?

      scores.map
            .with_index { |player, i| format("%2i #{player.formatted}", i + 1) }
            .unshift(format('%2s %10s %6s', '', 'Name', 'Points'))
    end

    def check_guess(input)
      puts @game.check_guess(input)
      Messages.tries_left(@game.tries_left)
    rescue ArgumentError => ex
      puts ex.message, "\n"
    end

    def save_score
      print 'Do you want to save your score? y/[n]: '

      return unless gets.chomp.casecmp('y').zero?

      begin
        print 'Type your name: '
        @game.save_score(gets.chomp)
        puts 'Your score was saved.'
      rescue ArgumentError => ex
        puts ex.message, "\n"
        retry
      end
    end
  end
end
