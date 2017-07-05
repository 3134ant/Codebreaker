module Codebreaker
  class Player
    def initialize(name, tries_left, hints_left)
      self.name = name
      @tries_left = tries_left
      @hints_left = hints_left
    end

    def formatted
      format('%10s %6i', @name, points)
    end

    def as_json
      { name: @name, points: points }
    end

    def to_json(*options)
      as_json.to_json(*options)
    end

    def points
      100 * (@tries_left + 1) + 75 * @hints_left
    end

    private

    def name=(value)
      msg = 'The name must be between 1 and 10 characters long'
      raise(ArgumentError, msg) unless (1...10).cover? value.length
      @name = value
    end
  end
end
