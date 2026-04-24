public class LRTA
{
  HashMap<Node, Float> H = new HashMap<>(); // Learned heuristic values
  float collisionPenalty = 10.0f;


  public Node LRTA_step(Tank self, Node current, boolean isExploring) {
    if (current == null) {
      println("LRTA*: current == null");
      return null;
    }

    // Use different heuristic initialization based on mode
    Node target = isExploring ? null : self.goalNode;

    if (!H.containsKey(current)) {
      H.put(current, estimateHeuristic(current, target));
    }

    Node bestNeighbor = null;
    float bestCost = Float.MAX_VALUE;

    for (Node neighbor : current.neighbors) {
      if (!neighbor.isTraversable()) continue;

      // When returning to base, DON'T skip visited nodes
      if (isExploring && neighbor.exploredState == ExploredState.VISITED) {
        if (!self.knownMap.containsValue(neighbor)) continue;
      }

      if (!H.containsKey(neighbor)) {
        H.put(neighbor, estimateHeuristic(neighbor, target));
      }

      float stepCost = cost(self, current, neighbor);
      float estimatedTotalCost = stepCost + H.get(neighbor);

      if (estimatedTotalCost < bestCost) {
        bestCost = estimatedTotalCost;
        bestNeighbor = neighbor;
      }
    }

    if (bestNeighbor == null) return current;

    updateHeuristic(self, current, target);
    return bestNeighbor;
  }

  void updateHeuristic(Tank self, Node n, Node target) {
    float minCost = Float.MAX_VALUE;
    boolean isExploring = (target == null);

    for (Node neighbor : n.neighbors) {
      if (!neighbor.isTraversable()) continue;

      if (isExploring && neighbor.exploredState == ExploredState.VISITED) {
        if (!self.knownMap.containsValue(neighbor)) continue;
      }

      float stepCost = cost(self, n, neighbor);
      float totalCost = stepCost + H.getOrDefault(neighbor, estimateHeuristic(neighbor, target));

      if (totalCost < minCost) {
        minCost = totalCost;
      }
    }

    if (minCost != Float.MAX_VALUE) {
      H.put(n, minCost);
    }
  }

  float estimateHeuristic(Node n, Node target) {
    // If node is not traversable, return max cost
    if (!n.isTraversable()) return Float.MAX_VALUE;

    // If we have a target (e.g., going to base), always use Manhattan distance
    if (target != null) {
      return (float)(Math.abs(n.col - target.col) + Math.abs(n.row - target.row));
    }

    // Only use exploration-based heuristic when exploring (target == null)
    if (n.exploredState == ExploredState.VISITED) return 2.0f;
    // if (n.exploredState == ExploredState.PENDING) return 3.0f;
    return 0.0f; // Unexplored nodes are most attractive when exploring
  }

  float cost(Tank self, Node a, Node b) {

    return  dist(a.position.x, a.position.y, b.position.x, b.position.y) / self.cellSize;
  }

  void handleCollision(Node badNode) {
    float currentH = H.getOrDefault(badNode, estimateHeuristic(badNode, null));
    H.put(badNode, currentH + collisionPenalty);
    println("Collision reported on the way to node (" + badNode.col + "," + badNode.row + "), H increased to " + H.get(badNode));
  }
}
