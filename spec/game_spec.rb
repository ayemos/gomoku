require 'gomoku'
require 'gomoku/game'

describe Gomoku::Game do
  let(:game) { Gomoku::Game.new }
  let(:board) { Gomoku::Board.new(4) }
  let(:node) { Gomoku::Game::Node.new(board, :white) }

end

