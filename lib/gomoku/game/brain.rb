module Gomoku
  class Game
    module Brain
      def minmax(player, node, depth)
        binding.pry
        alpha_beta(player, node, depth, -1 * Float::INFINITY, 1 * Float::INFINITY)
        if player == node.turn
          node.children.select{|c| !c.pos.nil?}.sort{|a, b|
            b.pos.nil? ? -1 : b.value <=> a.value
          }.first
        else
          node.children.select{|c| !c.pos.nil?}.sort{|a, b|
            b.pos.nil? ? -1 : a.value <=> b.value
          }.first
        end
      end

      def alpha_beta(player, node, depth, alpha, beta)
        node.board.pretty

        if judge(node.board) || depth == 0
          return node.value = evaluate(node, player) # node の評価値
        else
          node.pos = [0, 0]
          node.board.available_positions.shuffle.each do |x, y|
            node.board.push(node.turn, x, y)
            child = Gomoku::Game::Node.new(node.board, next_turn(node.turn))
            node.append_child(child)
            val = alpha_beta(player, child, depth - 1, alpha, beta)
            node.board.undo

            if node.turn == player
              if val >= alpha
                alpha = val
                node.value = val
                node.pos = [x, y]
                return node.value
              end
            else
              if val <= beta
                beta = val
                node.value = val
                node.pos = [x, y]
                return node.value
              end
            end
          end

          if node.turn == player
            return node.value = alpha
          else
            return node.value = beta
          end
        end
      end
    end

    def evaluate(node, color)
      unless judge(node.board).nil?
        if judge(node.board) == color
          return Float::INFINITY
        else
          return -1 * Float::INFINITY
        end
      end

      kills = killed = 0
      node.board.available_positions.shuffle.each do |x, y|
        node.board.push(color, x, y)

        kills += 1 if judge(node.board) == color
        killed += 1 if judge(node.board) == next_turn(color)

        node.board.undo
      end

      puts "kills:#{kills}, killed:#{killed}"
      if node.turn == color
        # 自分の手番 => 自分にリーチがあれば +INF
        if kills >= 1
          return Float::INFINITY
        end

        # 相手にダブルリーチがあれば +INF
        if killed >= 2
          return -1 * Float::INFINITY
        end
      else
        # 相手の手番 => 相手にリーチがあれば -INF
        if killed >= 1
          return -1 * Float::INFINITY
        end

        # 自分にダブルリーチがあれば +INF
        if kills >= 2
          return Float::INFINITY
        end
      end

      # 盤面評価
      score = 0.0

      r = node.board.radius
      b3d = node.board.to_3d_grid
      r.times do |x|
        r.times do |y|
          r.times do |h|
            if b3d[x][y][h] == color
              score += score_for_coordinate(r, x, y, h)
            end
          end
        end
      end

      # リーチとかキャメルとか
      score
    end

    def next_turn(turn)
      turn == :white ? :black : :white
    end

    def judge(board)
      b3d = board.to_3d_grid
      radius = board.radius

      # 底面
      radius.times do |x|
        radius.times do |y|
          next if b3d[x][y].empty?

          tmp_x, tmp_y = x, y
          color = b3d[tmp_x][tmp_y].first

          [-1, 0, 1].each do |dx|
            [-1, 0, 1].each do |dy|
              h = 0
              tmp_x, tmp_y = x, y

              while tmp_x >= 0 && tmp_x < radius &&
                tmp_y >= 0 && tmp_y < radius &&
                h < radius &&
                b3d[tmp_x][tmp_y][h] == color do
                  h += 1
                  tmp_x += dx
                  tmp_y += dy
              end

              if h == board.radius
                return color
              end
            end
          end
        end
      end

      # 側面
      board.radius.times do |y|
        board.radius.times do |h|
          next if b3d[0][y][h].nil?

          tmp_h, tmp_y = h, y
          color = b3d[0][tmp_y].first

          [-1, 0, 1].each do |dh|
            [-1, 0, 1].each do |dy|
              x = 0
              tmp_h, tmp_y = h, y

              while tmp_h >= 0 && tmp_h < radius &&
                tmp_y >= 0 && tmp_y < radius &&
                x < radius &&
                b3d[x][tmp_y][tmp_h] == color do
                x += 1
                tmp_h += dh
                tmp_y += dy
              end

              if x == board.radius
                return color
              end
            end
          end
        end
      end

      nil
    end

    def score_for_coordinate(r, x, y, h)
      if [x, r - x].min == 0 && [y, r - y].min == 0
        5.0
      else
        3.0
      end
    end
  end
end
