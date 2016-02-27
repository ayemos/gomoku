module Gomoku
  class Game
    class Node
      attr_accessor :value, :board, :turn, :children, :pos, :mts_notes, :parent

      def initialize(board, turn, value=0, pos=[0,0])
        @board = board
        @turn = turn
        @value = value
        @children = []
        @parent = nil
        @mts_notes = {
          initial: true,
          wins: 0,
          trials: 0
        }
        @pos = pos
      end

      def append_child(node)
        node.parent = self
        @children << node
      end

      def remove_child(node)
        node.parent = nil
        @children.delete(node)
      end

      def remove_all_children
        @children.each do |c|
          c.parent = nil
        end

        @children = []
      end
    end
  end
end
