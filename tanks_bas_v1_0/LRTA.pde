//Asawin Sitthi assi7068
//Chris Pilegård chpi8651
public class LRTA
{
  HashMap<Node, Float> H = new HashMap<>(); // Learned heuristic values
  float collisionPenalty = 10.0f;



  /**  LRTA* (Learning Real-Time A*) step function
   * This function implements the LRTA* algorithm for online pathfinding in unknown environments.
   *
   * Based on Figure 4.24 in:
   * Russell and Norvig (2021). Artificial Intelligence: A Modern Approach, Global Edition, 4th ed.
   * Chapter 4 "Search in Complex Environments", Section 4.5 "Online Search Agents and Unknown Environments", p.158
   *
   * LRTA* selects actions based on neighboring state values, which are updated as the agent
   * moves through the state space. This allows learning from experience in real-time.
   *
   * @param self - The tank agent making the decision
   * @param current - The current node the agent is on
   * @param isExploring - If true, agent explores (no specific goal); if false, navigates to goalNode
   * @return The best neighboring node to move to, or current node if no valid neighbors exist
   **/
  public Node LRTA_step(Tank self, Node current, boolean isExploring) {
    if (current == null) {
      println("LRTA*: current == null");
      return null;
    }

    Node target = isExploring ? null : self.goalNode;

    if (!H.containsKey(current)) {
      H.put(current, estimateHeuristic(current, target));
    }

    Node bestNeighbor = null;
    float minCost = Float.MAX_VALUE;

    for (Node neighbor : current.neighbors) {
      if (!neighbor.isTraversable()) continue;

      if (!H.containsKey(neighbor)) {
        H.put(neighbor, estimateHeuristic(neighbor, target));
      }

      float stepCost = cost(self, current, neighbor);
      float totalCost = stepCost + H.get(neighbor);

      if (totalCost < minCost) {
        minCost = totalCost;
        bestNeighbor = neighbor;
      }
    }

    if (bestNeighbor == null) return current;

    if (minCost != Float.MAX_VALUE) {
      H.put(current, minCost);
    }

    return bestNeighbor;
  }

  /**  Estimate the heuristic value for a node
   * Two modes:
   * 1. Goal-directed (target != null): Uses Manhattan distance to goal
   * 2. Exploration (target == null): Prioritizes unexplored nodes
   *
   * @param n - The node to estimate heuristic for
   * @param target - The goal node (or null for exploration mode)
   * @return Estimated cost-to-goal (lower is better)
   */
  float estimateHeuristic(Node n, Node target) {
    if (!n.isTraversable()) return 10000;

    if (target != null) {
      return (float)(Math.abs(n.col - target.col) + Math.abs(n.row - target.row));
    }

    if (n.exploredState == ExploredState.VISITED) return 2.0f;
    // if (n.exploredState == ExploredState.PENDING) return 3.0f;
    return 0.0f;
  }


  /** Calculate the actual cost of moving from node a to node b
   *  Uses Euclidean distance normalized by cell size.
   *
   * @param self - The tank agent (for accessing cellSize)
   * @param a - Starting node
   * @param b - Destination node
   * @return The step cost (distance-based)
   */
  float cost(Tank self, Node a, Node b) {

    return  dist(a.position.x, a.position.y, b.position.x, b.position.y) / self.cellSize;
  }

  /**  Handle collision detection by penalizing the problematic node
   * When the agent collides while trying to reach a node, increase that node's
   * heuristic value to make it less attractive in future planning.
   *
   * @param badNode - The node that led to a collision
   */
  void handleCollision(Node badNode) {
    float currentH = H.getOrDefault(badNode, estimateHeuristic(badNode, null));
    H.put(badNode, currentH + collisionPenalty);
    println("Collision reported on the way to node (" + badNode.col + "," + badNode.row + "), H increased to " + H.get(badNode));
  }
}
