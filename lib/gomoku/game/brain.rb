require 'awesome_print'
module Gomoku
  class Game
    module Brain
      FACTORS = {
        kills:                30.0,
        killed:               -30.0,
        chances:              10.0,
        crisises:             -10.0,
        coordinates_corner:   10.0,
        coordinates_side:     6.0,
        coordinates_center:   8.0
      }

      MTS_C = 0.3

      JUDGE_CACHE = {}

      def mts(player, node, n)
        node.remove_all_children
        node.board.available_positions.map{|x, y|
          node.board.push(node.turn, x, y)

          new_board = Gomoku::Board.new(node.board.radius)
          shallow_copy_pins(node.board, new_board)
          new_board.turns = node.board.turns

          child = Gomoku::Game::Node.new(new_board, next_turn(node.turn))
          node.append_child(child)
          node.board.undo
        }

        n.times do |t|
          if node.children.any?{|c| c.mts_notes[:initial] }
            child = node.children.select{|c| c.mts_notes[:initial] }.first
            winner = playout(child)
            child.mts_notes[:trials] += 1
            child.mts_notes[:wins] += 1 if winner == player
            child.mts_notes[:initial] = false
            next
          end

          target_child = node.children.sort{|c1, c2|
            mts_factor(c2, t) <=> mts_factor(c1, t)
          }.first

          winner = playout(target_child)
          target_child.mts_notes[:trials] += 1
          target_child.mts_notes[:wins] += 1 if winner == player
        end

        node.children.sort{|c1, c2|
          c2.mts_notes[:trials] <=> c1.mts_notes[:trials]
        }.first
      end

      def mts_mt(player, node, n)
        node.remove_all_children
        node.board.available_positions.map{|x, y|
          node.board.push(node.turn, x, y)

          new_board = Gomoku::Board.new(node.board.radius)
          shallow_copy_pins(node.board, new_board)
          new_board.turns = node.board.turns

          child = Gomoku::Game::Node.new(new_board, next_turn(node.turn))
          node.append_child(child)
          node.board.undo
        }

        while node.children.any?{|c| c.mts_notes[:initial] }
          child = node.children.select{|c| c.mts_notes[:initial] }.first
          winner = playout(child)
          child.mts_notes[:trials] += 1
          child.mts_notes[:wins] += 1 if winner == player
          child.mts_notes[:initial] = false
          next
        end

        n.times do |t|
          # select most hopeful child
          target_child = node.children.sort{|c1, c2|
            mts_factor(c2, t) <=> mts_factor(c1, t)
          }.first

          # playout
          winner = playout(target_child)

          # store results
          target_child.mts_notes[:trials] += 1
          target_child.mts_notes[:wins] += 1 if winner == player
        end

        node.children.sort{|c1, c2|
          c2.mts_notes[:trials] <=> c1.mts_notes[:trials]
        }.first
      end

      def playout_test(player, node, n)
        scores = node.board.available_positions.map{|x, y|
          node.board.push(node.turn, x, y)
          node.turn = next_turn(node.turn)

          wins = 0
          n.times do
            wins += 1 if playout(node) == player
          end

          node.board.undo
          node.turn = next_turn(node.turn)

          puts "X:Y = #{x}:#{y}"
          puts "WIN RATE: #{wins.to_f / n}"

          [[x, y], wins.to_f / n]
        }.to_h

        scores.sort{|(_, v1), (_, v2)| v2 <=> v1}
      end

      def initialize
        @c = 0
      end

      def minmax(player, node, depth)
        @c = 0
        node.remove_all_children
        node.value = 0
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

        puts @c
      end

      def alpha_beta(player, node, depth, alpha, beta)
        @c += 1
        min = Float::INFINITY
        max = -1 * Float::INFINITY

        # node.board.pretty

        if ((node.board.turns >= node.board.radius * 2 - 1) && !judge(node.board).nil?)|| depth == 0
          return node.value = evaluate(node, player) # node の評価値
        else
          node.pos = nil
          # sorted_positions(node).each do |x, y|
          node.board.available_positions.shuffle.each do |x, y|
            node.board.push(node.turn, x, y)

            new_board = Gomoku::Board.new(node.board.radius)
            shallow_copy_pins(node.board, new_board)
            new_board.turns = node.board.turns

            child = Gomoku::Game::Node.new(new_board, next_turn(node.turn))
            node.append_child(child)

            alpha_beta(player, child, depth - 1, alpha, beta)
            node.board.undo

            if node.turn == player
              if child.value > max
                alpha = child.value
                node.pos = [x, y]
                node.value = max = child.value
              end

              if node.value > beta
                return node.value
              end
            else
              if child.value < min
                beta = child.value
                node.pos = [x, y]
                node.value = min = child.value
              end

              if node.value < alpha
                return node.value
              end
            end
          end

          if node.turn == player
            return alpha
          else
            return beta
          end
        end

        return node.value
      end
    end

    def evaluate_light(node, color)
      evaluate_coordinates(node, color)
    end

    def evaluate(node, color)
      score = 0.0
      if node.board.turns >= node.board.radius * 2 - 1
        # 決着判定
        score = evaluate_judge(node, color)
        return score if score == Float::INFINITY || score == -1 * Float::INFINITY

        # リーチ判定
        score = evaluate_kills(node, color)
        return score if score == Float::INFINITY || score == -1 * Float::INFINITY
      end


      ##############################
      # こっからヒューリスティクス #
      ##############################
      # リーチ一歩手前判定
      score += evaluate_chances(node, color)

      # 雑な盤面判定
      score += evaluate_coordinates(node, color)

      score
    end

    def evaluate_judge(node, color)
      unless (winner = judge(node.board)).nil?
        if winner == color
          return Float::INFINITY
        else
          return -1 * Float::INFINITY
        end
      end
    end

    def evaluate_kills(node, color)
      kills = killed = 0
      node.board.available_positions.each do |x, y|
        node.board.push(color, x, y)

        winner = judge(node.board)
        kills += 1 if winner == color
        killed += 1 if winner == next_turn(color)

        node.board.undo

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
      end

      return kills * FACTORS[:kills] + killed * FACTORS[:killed]
    end

    def sorted_positions(node)
      r = node.board.radius

      @sorted_positions ||= node.board.available_positions.sort{|p1, p2|
        s1 = s2 = 0

        p1.each do |c|
          s1 += 1 if c == 0 || r - c == 0
        end

        p2.each do |c|
          s2 += 1 if c == 0 || r - c == 0
        end

        s2 <=> s1
      }

      @sorted_positions & node.board.available_positions

=begin
      node.board.available_positions.sort do |p1, p2|
        node.board.push(node.turn, p1[0], p1[1])
        s1 = evaluate_light(node, node.turn)
        node.board.undo

        node.board.push(node.turn, p2[0], p2[1])
        s2 = evaluate_light(node, node.turn)
        node.board.undo

        s2 <=> s1
      end
=end
    end

    def evaluate_chances(node, color)
      chances = 0
      crisises = 0

      node.board.available_positions.each do |x1, y1|
        node.board.push(color, x1, y1)

        node.board.available_positions.each do |x2, y2|
          node.board.push(color, x2, y2)

          winner = judge(node.board)
          chances += 1 if winner == color
          crisises += 1 if winner == next_turn(color)

          node.board.undo
        end

        node.board.undo
      end

      return chances * FACTORS[:chances] + crisises * FACTORS[:crisises]
    end

    def evaluate_coordinates(node, color)
      r = node.board.radius
      b3d = node.board.to_3d_grid
      score = 0.0
      Array(0..r-1).repeated_permutation(3).each do |x, y, h|
        if b3d[x][y][h] == color
          if (x == 0 || r - x == 0) && (y == 0 || r - y == 0)
            score += FACTORS[:coordinates_corner]
          else
            score += FACTORS[:coordinates_side]
          end
        end
      end

      score
    end

    def next_turn(turn)
      turn == :white ? :black : :white
    end

    def judge(board)
      b3d = board.to_3d_grid
      if JUDGE_CACHE.has_key?(b3d.hash)
        return JUDGE_CACHE[b3d.hash]
      end
      radius = board.radius

      Array(0..radius-1).repeated_permutation(3) do |x, y, h|
        next if b3d[x][y].empty? || b3d[x][y][h].nil?
        next if x != 0 && y != 0 && h != 0

        color = b3d[x][y][h]

        Array(-1..1).repeated_permutation(3) do |dx, dy, dh|
          next if dx == 0 && dy == 0 && dh == 0

          tmp_x, tmp_y, tmp_h = x, y, h
          c = 0

          while (tmp_x >= 0 && tmp_x < radius) &&
                (tmp_y >= 0 && tmp_y < radius) &&
                (tmp_h >= 0 && tmp_h < radius) &&
                b3d[tmp_x][tmp_y][tmp_h] == color
            c += 1
            tmp_x += dx
            tmp_y += dy
            tmp_h += dh
          end

          if c == board.radius
            return JUDGE_CACHE[b3d.hash] = color
          end
        end
      end

      JUDGE_CACHE[b3d.hash] = nil
    end

    def playout(node)
      turn = node.turn
      c = 0
      while (winner = judge(node.board)).nil? &&
        !(available_positions = node.board.available_positions).empty?

        pos = available_positions.sample(1).first
        node.board.push(turn, pos[0], pos[1])
        turn = next_turn(turn)
        c += 1
      end

      c.times do
        node.board.undo
      end

      winner
    end

    def mts_factor(node, n)
      (node.mts_notes[:wins].to_f / node.mts_notes[:trials]) \
        + MTS_C * Math.sqrt(Math.log(n).to_f / node.mts_notes[:trials])
    end

    def shallow_copy_pins(b1, b2)
      b2.pins = []
      b1.pins.each do |pin|
        b2.pins << Array.new(pin)
      end
    end
  end
end
