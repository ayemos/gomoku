module Gomoku
  class Board
    COLORS = %i(black white)
    DEFAULT_RADIUS = 4

    attr_accessor :pins, :radius

    def initialize(radius=DEFAULT_RADIUS)
      @radius = radius
      @pins = Array.new(radius*radius){[]}
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
      @pins
    end

    def undo
      if undo_stack.empty?
        puts "No history!"
        return
      end

      x, y = undo_stack.pop
      @pins[x + y * @radius].pop
    end

    def available_positions
      ret = []
      @radius.times do |x|
        @radius.times do |y|
          if @pins[x + y * @radius].count < @radius
            ret << [x, y]
          end
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
      @radius.times do |h|
        puts "#{h + 1}-th layer"

        @radius.times do |x|
          @radius.times do |y|
            print "#{to_3d_grid[x][y][h]},\t"
          end
          puts ''
        end

        puts ''
      end
    end

    private

    def undo_stack
      @undo_stack ||= []
    end
  end
end
