module Codebreaker
  class Game
    MIN = 1
    MAX = 6
    LENGTH = 4

    REGEXP = Regexp.new("^[#{MIN}-#{MAX}]{#{LENGTH}}$")

    TRIES = 10
    HINTS = 3

    private_constant :MIN, :MAX, :LENGTH, :REGEXP, :TRIES, :HINTS
    attr_reader :tries_left, :hints_left

    def start
      @code = Array.new(LENGTH) { rand(MIN..MAX) }.join
      @indexes_for_hint = (0...LENGTH).to_a

      @tries_left = TRIES
      @hints_left = HINTS

      @finished = false
      @won = false
    end

    def check_guess(input)
      verify input

      @tries_left -= 1

      result = check_input(@code.chars, input.chars)
      define_stage result
      result
    end

    def hint
      return false if @hints_left.zero?

      @tries_left -= 1
      @hints_left -= 1
      define_stage

      generate_hint
    end

    def finished?
      @finished
    end

    def won?
      @won
    end

    def answer
      @code if finished?
    end

    def save_score(name, file_name = 'scores.yml')
      player = Player.new(name, @tries_left, @hints_left)

      scores = process_file(file_name)
      scores << player
      scores = scores.max_by(10, &:points)

      File.open(file_name, 'w') { |f| f.write scores.to_yaml }
    end

    def high_scores(file_name = 'scores.yml')
      process_file file_name
    end

    def as_json
      {
        result: nil,
        hint: nil,
        tries_left: @tries_left,
        hints_left: @hints_left,
        finished: finished?,
        won: won?,
        answer: answer
      }
    end

    def to_json(*options)
      as_json.to_json(*options)
    end

    private

    def check_input(code_chars, input_chars)
      num_of_pluses = LENGTH.times.count { |i| code_chars[i] == input_chars[i] }

      input_chars.each do |char|
        next unless code_chars.include? char
        code_chars.delete_at(code_chars.index(char))
      end

      num_of_minuses = LENGTH - num_of_pluses - code_chars.size

      ('+' * num_of_pluses) + ('-' * num_of_minuses)
    end

    def generate_hint
      hint = '_' * LENGTH
      index = @indexes_for_hint.delete(@indexes_for_hint.sample)
      hint[index] = @code[index]
      hint
    end

    def define_stage(result = '')
      if result == ('+' * LENGTH)
        @finished = true
        @won = true
      elsif @tries_left.zero?
        @finished = true
      end
    end

    def process_file(file_name)
      return [] if !File.exist?(file_name) || File.zero?(file_name)
      YAML.load_file(file_name)
    end

    def verify(input)
      msg = "Guesses must consist of #{LENGTH} digits from #{MIN} to #{MAX}"
      raise(ArgumentError, msg) if !input.is_a?(String) || !input.match?(REGEXP)
    end
  end
end
