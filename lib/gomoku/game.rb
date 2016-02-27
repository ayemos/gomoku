require 'gomoku/game/brain'
require 'gomoku/game/node'

require 'benchmark/ips'

module Gomoku
  class Game
    include Brain

    def bench
      board = Gomoku::Board.new(3);
      board.push(:white, 0, 0)
      board.push(:white, 1, 0)
      board.push(:white, 2, 0)
      board.push(:black, 1, 0)
      board.push(:black, 1, 2)
      board.push(:black, 2, 1)

      node = Gomoku::Game::Node.new(board, :white)
      Benchmark.ips do |x|
        x.report("sorted_positions") { sorted_positions(node) }
        x.report("evaluate") { evaluate(node, node.turn) }
        x.report("evaluate_light") { evaluate_light(node, node.turn) }
        x.report("evaluate.chances") { evaluate_chances(node, node.turn) }
        x.report("evaluate.coordinates") { evaluate_coordinates(node, node.turn) }
        x.report("evaluate.kills") { evaluate_kills(node, node.turn) }
        x.report("evaluate.judge") { evaluate_judge(node, node.turn) }
        x.report("node.judge") { judge(node.board) }
        x.report("playout") { playout(node) }
      end
    end

    def next_turn(turn)
      turn == :white ? :black : :white
    end
  end
end
