module Codebreaker
  class Message
    class << self
      def logo
        puts "Code Breaker"
      end

      def welcome
        puts 'Welcome to the game! Choose one options:'
      end

      def run
        puts "\n" \
             "1 - play        \n" \
             "2 - high scores \n" \
             "0 - exit        \n" \
             "\n"
      end

      def play
        puts "Let's go! \n" \
             "\n" \
             "1 - hint  \n" \
             "0 - end   \n" \
             "\n"
      end

      def win(answer)
        puts 'Congratulations! You are the winner!', "It was #{answer}.", "\n"
      end

      def lose(answer)
        puts 'Sorry, you lose(((', "It was #{answer}.", "\n"
      end

      def tries_left(tries_left)
        puts "#{tries_left} tries left.", "\n"
      end

      def hint(hint, hints_left, tries_left)
        if hint
          puts "Hint #{hint}.", "#{hints_left} hints_left."
          tries_left(tries_left)
        else
          puts 'No hints left.', "\n"
        end
      end

      def bye
        puts 'Good luck!'
      end

      def wrong_option
        puts 'Wrong option!'
      end
    end
  end
end
