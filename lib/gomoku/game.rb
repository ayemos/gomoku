require 'gomoku/game/brain'
require 'gomoku/game/node'

module Gomoku
  class Game
    include Brain

    def test(inits,n=1000)
      wins = 0
      lose = 0
      draw = 0

      n.times do |m|
        board = Gomoku::Board.new(4)

        turn = m % 2 == 0 ? :white : :black

        inits.each do |x, y|
          board.push(turn, x, y)
          turn = next_turn(turn)
        end

        loop do
          pos = board.available_positions.sample(1).first
          if pos.nil?
            draw += 1
            break
          end
          board.push(turn, pos[0], pos[1])

          if judge(board) == :white
            wins += 1
            break
          elsif judge(board) == :black
            lose += 1
            break
          end

          turn = next_turn(turn)
        end
      end

      puts "WIN RATE:#{wins.to_f / n}"
      puts "LOSE RATE:#{lose.to_f / n}"
      puts "DRAW RATE:#{draw.to_f / n}"
    end

    def next_turn(turn)
      turn == :white ? :black : :white
    end
  end
end
