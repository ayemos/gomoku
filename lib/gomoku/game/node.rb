module Gomoku
  class Game
    class Node
      attr_accessor :value, :board, :turn, :children, :pos

      def initialize(board, turn, value=0)
        @board = Gomoku::Board.new(board.radius)
        shallow_copy_pins(board, @board)
        @turn = turn
        @value = value
        @children = []
      end

      def append_child(node)
        @children << node
      end

      def remove_child(node)
        @children.delete(node)
      end

      private

      def shallow_copy_pins(b1, b2)
        b2.pins = []
        b1.pins.each do |pin|
          b2.pins << Array.new(pin)
        end
      end
    end
  end
end
