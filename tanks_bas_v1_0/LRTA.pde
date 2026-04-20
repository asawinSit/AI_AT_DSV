class  LRTA
{
  // Real-time A* learning
  HashMap<Node, Float> H = new HashMap<>(); // Learned heuristic values
  /**
   * Get learned or estimated heuristic for a node (used by A* for base return)
   */
  float getHeuristic(Tank self, Node n) {
    if (H.containsKey(n)) {
      return H.get(n); // Use learned value from LRTA*
    }

    // Initialize with estimate based on distance to base
    if (n.type == NodeType.HOME_BASE) {
      return 0.0;
    }
    return n.distanceFromBase * self.cellSize; // Grid distance estimate
  }

  /**
   * Update heuristic values based on actual path cost (LEARNING)
   */
  void updateHeuristic(Tank self, HashMap<Node, Float> gScore, Node goalNode) {
    float actualCostToGoal = gScore.get(goalNode);

    // Update heuristic for all nodes in gScore
    for (Node n : gScore.keySet()) {
      float actualRemainingCost = actualCostToGoal - gScore.get(n);
      float currentH = getHeuristic(self, n);

      // Learning rate weighted update
      float learningRate = 0.3;
      float newH = currentH * (1 - learningRate) + actualRemainingCost * learningRate;
      H.put(n, newH);
    }
  }

  Node getLowestFScore(ArrayList<Node> openSet, HashMap<Node, Float> fScore) {
    Node best = openSet.get(0);
    float bestScore = fScore.getOrDefault(best, Float.MAX_VALUE);

    for (Node n : openSet) {
      float score = fScore.getOrDefault(n, Float.MAX_VALUE);
      if (score < bestScore) {
        bestScore = score;
        best = n;
      }
    }
    return best;
  }

  void reconstructPath(Tank self, HashMap<Node, Node> cameFrom, Node current) {
    self.path.clear();
    while (cameFrom.containsKey(current)) {
      self.path.add(0, current);
      current = cameFrom.get(current);
    }
  }

  // ==================== LRTA* ALGORITHM ====================

  /**
   * LRTA* (Learning Real-Time A*) - Single step lookahead with learning
   * Only considers immediate neighbors, not full path planning
   */
  Node LRTA_step(Tank self, Node current) {
    if (current == null) return null;

    // Initialize heuristic if first time seeing this node
    if (!H.containsKey(current)) {
      H.put(current, estimateHeuristic(current));
    }

    Node bestNeighbor = null;
    float bestCost = Float.MAX_VALUE;

    // 1. LOOKAHEAD: Evaluate all traversable neighbors
    for (Node neighbor : current.neighbors) {
      if (!neighbor.isTraversable()) continue;
      if (neighbor.exploredState == ExploredState.UNEXPLORED) {
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
      if (neighbor.exploredState == ExploredState.UNEXPLORED) {
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
    if (n.type == NodeType.ENEMY_BASE) {
      return 0.0; // Goal state
    } else if (n.exploredState == ExploredState.UNEXPLORED) {
      return 10.0; // Encourage exploration
    } else if (n.exploredState == ExploredState.VISIBLE) {
      return 20.0; // Slightly less attractive
    } else if (n.exploredState == ExploredState.VISITED) {
      return 50.0; // Discourage revisiting
    }
    return 30.0;
  }

  float cost(Node a, Node b) {
    return dist(a.position.x, a.position.y, b.position.x, b.position.y);
  }
}