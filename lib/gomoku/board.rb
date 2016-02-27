module Gomoku
  class Board
    COLORS = %i(black white)
    DEFAULT_RADIUS = 4

    attr_accessor :pins, :radius, :turns

    def initialize(radius=DEFAULT_RADIUS)
      @radius = radius
      @pins = Array.new(radius*radius){[]}
      @turns = 0
    end

    def push(color, x, y)
      unless COLORS.include?(color)
        puts "invalid color: #{color}"
        return
      end

      if @pins[x + y * @radius].count >= @radius
        puts "pin is full: #{x},#{y}"
        return
      end

      @pins[x + y * @radius] << color
      undo_stack << [x, y]
      @turns += 1
      @pins
    end

    def undo
      if undo_stack.empty?
        puts "No history!"
        return
      end

      x, y = undo_stack.pop
      @pins[x + y * @radius].pop
      @turns -= 1
    end

    def available_positions
      ret = []
      Array(0..@radius-1).repeated_permutation(2) do |x, y|
        if @pins[x + y * @radius].count < @radius
          ret << [x, y]
        end
      end

      ret
    end

    def to_3d_grid
      res = Array.new(Array.new)
      @radius.times do |n|
        tmp = []
        @radius.times do |m|
          tmp << @pins[m + n * @radius]
        end
        res << tmp
      end

      res
    end

    def pretty
      (@radius-1).downto(0) do |h|
        print "\t" * h
        puts '┌' + '───┬' * (@radius - 1) + '───┐'
        @radius.times do |x|
          print "\t" * h

          @radius.times do |y|
            print "│ #{to_3d_grid[x][y][h].to_s.upcase[0] || ' '} "
          end
          puts '│'
          print "\t" * h
          if x == (@radius - 1)
            puts '└' + '───┴' * (@radius - 1) + '───┘'
          else
            puts '├' + '───┼' * (@radius - 1) + '───┤'
          end
        end
      end
    end

    private

    def undo_stack
      @undo_stack ||= []
    end
  end
end
