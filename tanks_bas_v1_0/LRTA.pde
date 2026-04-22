public class LRTA
{
  HashMap<Node, Float> H = new HashMap<>(); // Learned heuristic values
  float collisionPenalty = 20.0f;

  public Node LRTA_step(Tank self, Node current) {
    if (current == null) {
      println("LRTA*: current == null");
      return null;
    }

    // Initialize heuristic if first time seeing this node
    if (!H.containsKey(current)) {
      H.put(current, estimateHeuristic(current, self.goalNode)); // Pass target when go back to base
    }

    Node bestNeighbor = null;
    float bestCost = Float.MAX_VALUE;

    // Evaluate all traversable neighbors
    for (Node neighbor : current.neighbors) {
      // Skip non-traversable nodes
      if (!neighbor.isTraversable()) continue;

      // Skip visited nodes that aren't in the known map
      if (neighbor.exploredState == ExploredState.VISITED) {
        if (!self.knownMap.containsValue(neighbor)) continue;
      }

      // Initialize neighbor's heuristic if not already
      if (!H.containsKey(neighbor)) {
        H.put(neighbor, estimateHeuristic(neighbor, self.goalNode)); // Pass target
      }

      // Calculate cost estimate to goal
      float stepCost = cost(current, neighbor);
      float estimatedTotalCost = stepCost + H.get(neighbor);

      if (estimatedTotalCost < bestCost) {
        bestCost = estimatedTotalCost;
        bestNeighbor = neighbor;
      }
    }

    if (bestNeighbor == null) return current;

    // Update current node's heuristic based on the best neighbor found
    updateHeuristic(self, current);
    //println("Tank " + self.tank_id + " LRTA* learning: H(" + current.col + "," + current.row + ") = " + H.get(current));

    return bestNeighbor;
  }

  void updateHeuristic(Tank self, Node n) {
    float minCost = Float.MAX_VALUE;

    for (Node neighbor : n.neighbors) {
      if (!neighbor.isTraversable()) continue;

      // Skip visited nodes that aren't in the known map
      if (neighbor.exploredState == ExploredState.VISITED) {
        if (!self.knownMap.containsValue(neighbor)) continue;
      }

      float stepCost = cost(n, neighbor);
      float totalCost = stepCost + H.getOrDefault(neighbor, estimateHeuristic(neighbor, self.goalNode)); // Pass target

      if (totalCost < minCost) {
        minCost = totalCost;
      }
    }

    // Only update if we found a valid neighbor
    if (minCost != Float.MAX_VALUE) {
      H.put(n, minCost);
    }
  }

  float estimateHeuristic(Node n, Node target) {
    // If node is not traversable, return max cost
    if (!n.isTraversable()) return Float.MAX_VALUE;

    // If we don't have a target, use exploration-based heuristic
    if (target == null) {
      if (n.exploredState == ExploredState.VISITED) return 5.0f;
      if (n.exploredState == ExploredState.PENDING) return 2.0f;
      return 0.0f;
    }

    return (float)(Math.abs(n.col - target.col) + Math.abs(n.row - target.row)) * 100;
  }

  float cost(Node a, Node b) {
    return dist(a.position.x, a.position.y, b.position.x, b.position.y);
  }

  void reportCollision(Node badNode) {
    float currentH = H.getOrDefault(badNode, estimateHeuristic(badNode, null));
    H.put(badNode, currentH + collisionPenalty);
    println("Collision reported at node (" + badNode.col + "," + badNode.row + "), H increased to " + H.get(badNode));
  }

  void handleCollision(Tank self, Node badNode) {
    // Penalize the collided node
    reportCollision(badNode);

    // Update the heuristic of the current node (where the tank is)
    updateHeuristic(self, self.currentNode);
  }
}
