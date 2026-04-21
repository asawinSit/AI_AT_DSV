public static class LRTA
{
  // Real-time A* learning
  HashMap<Node, Float> H = new HashMap<>(); // Learned heuristic values

  // ==================== LRTA* ALGORITHM ====================
  /**
   * LRTA* (Learning Real-Time A*) - Single step lookahead with learning
   * Only considers immediate neighbors, not full path planning
   */
  public Node LRTA_step(Tank self, Node current) {
    if (current == null)
    {
      println("LRTA*:" + " current == null" );
      return null;
    }

    // Initialize heuristic if first time seeing this node
    if (!H.containsKey(current)) {
      H.put(current, estimateHeuristic(current));
    }

    Node bestNeighbor = null;
    float bestCost = Float.MAX_VALUE;

    // 1. LOOKAHEAD: Evaluate all traversable neighbors
    for (Node neighbor : current.neighbors) {
      if (!neighbor.isTraversable()) continue;
      if (neighbor.exploredState == ExploredState.VISITED) {
        if (!self.knownMap.containsValue(neighbor)) continue;
      }

      // Initialize neighbor's heuristic if needed
      if (!H.containsKey(neighbor)) {
        H.put(neighbor, estimateHeuristic(neighbor));
      }

      // Cost = step cost + heuristic estimate to goal
      float stepCost = cost(current, neighbor);
      float estimatedTotalCost = stepCost + H.get(neighbor);

      if (estimatedTotalCost < bestCost) {
        bestCost = estimatedTotalCost;
        bestNeighbor = neighbor;
      }
    }

    if (bestNeighbor == null) return current;

    // 2. LEARNING: Update current node's heuristic (LRTA* learning rule)
    // H(current) = min over neighbors of [cost(current, neighbor) + H(neighbor)]
    float minCost = Float.MAX_VALUE;
    for (Node neighbor : current.neighbors) {
      if (!neighbor.isTraversable()) continue;
      if (neighbor.exploredState == ExploredState.VISITED) {
        if (!self.knownMap.containsValue(neighbor)) continue;
      }

      float stepCost = cost(current, neighbor);
      float totalCost = stepCost + H.getOrDefault(neighbor, estimateHeuristic(neighbor));
      if (totalCost < minCost) {
        minCost = totalCost;
      }
    }

    // Update the heuristic for current node (this is the key LRTA* learning step)
    H.put(current, minCost);

    println("Tank " + self.tank_id + " LRTA* learning: H(" + current.col + "," + current.row + ") = " + minCost);

    // 3. MOVE: Return the best neighbor (agent will move there)
    return bestNeighbor;
  }

  /**
   * Initial heuristic estimate before learning
   */
  float estimateHeuristic(Node n) {
    // Heuristic for exploration task
    float heuristicCost = 0;
    if (n.type == NodeType.ENEMY_BASE) {
      heuristicCost += 0.0; // Goal state
    } else if (n.type == NodeType.HOME_BASE) {
      heuristicCost += 200.0; // Encourage exploration
    } else if (n.exploredState == ExploredState.UNEXPLORED) {
      heuristicCost += 10.0; // Encourage exploration
    } else if (n.exploredState == ExploredState.VISIBLE) {
      heuristicCost += 20.0; // Slightly less attractive
    } else if (n.exploredState == ExploredState.PENDING) {
      heuristicCost += 70.0; // Slightly less attractive
    } else if (n.exploredState == ExploredState.VISITED) {
      heuristicCost += 100.0; // Discourage revisiting
    }
    return heuristicCost;
  }

  float cost(Node a, Node b) {
    return dist(a.position.x, a.position.y, b.position.x, b.position.y);
  }
}
