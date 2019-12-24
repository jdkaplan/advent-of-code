# frozen_string_literal: true

require 'set'

require 'pqueue'

module Search
  # start: state
  # get_neighbors: (state) => [state]
  # is_goal: (state) => boolean
  def self.bfs(start, get_neighbors, is_goal)
    queue = [[start]]
    visited = Set.new
    until queue.empty?
      path = queue.shift
      state = path[-1]
      next if visited.include? state

      visited << state
      return path if is_goal.call(state)

      children = get_neighbors.call(state).reject { |cell| visited.include? cell }
      children.each do |child|
        queue << path + [child]
      end
    end
    nil
  end

  State = Struct.new(:parent, :state, :cost) do
    def path
      states = [state]
      current = parent
      while current
        states << current.state
        current = current.parent
      end
      states.reverse
    end
  end

  # start: state
  # get_neighbors: (state) => [(state, cost)]
  # is_goal: (state) => boolean
  # heuristic: (state) => cost
  def self.uniform_cost(start, get_neighbors, is_goal, heuristic: ->(_state) { 0 })
    queue = PQueue.new do |a, b|
      (a.cost + heuristic.call(a.state)) < (b.cost + heuristic.call(b.state))
    end
    queue.push(State.new(nil, start, 0))

    expanded = Set.new
    until queue.empty?
      parent = queue.pop
      state = parent.state
      puts "#{parent.cost} #{parent.state}"
      next if expanded.include? state

      expanded << state
      return parent if is_goal.call(state)

      get_neighbors.call(state).each do |child, cost|
        queue.push(State.new(parent, child, parent.cost + cost))
      end
    end
    nil
  end

  def self.dijkstra(vertices, edges, start)
    dist = Hash.new(+Float::INFINITY)
    dist[start] = 0

    queue = Set.new(vertices)
    until queue.empty?
      u = queue.min_by { |v| dist[v] }
      queue.delete(u)

      edges[u].each_pair do |v, weight|
        next unless queue.include? v

        alt = dist[u] + weight
        dist[v] = alt if alt < dist[v]
      end
    end
    dist
  end

  def self.floyd_warshall(vertices, edges)
    dist = Hash.new { |hash, key| hash[key] = Hash.new(+Float::INFINITY) }
    edges.each { |u, v| dist[u][v] = edges[u][v] }
    vertices.each { |v| dist[v][v] = 0 }
    vertices.each do |k|
      vertices.each do |i|
        vertices.each do |j|
          d = dist[i][k] + dist[k][j]
          dist[i][j] = d if d < dist[i][j]
        end
      end
    end
    dist
  end
end
