
class Tank2 extends Tank {



  // own knowledge graph
  HashMap<String, Node> knownMap = new HashMap<String, Node>();

  LRTA LRTA_Nav = new LRTA();


  Tank2(int id, Team team, PVector _startpos, float _size, color _col) {
    super(id, team, _startpos, _size, _col);
    println("Tank " + tank_id + ": LRTA* found no valid move!");
  }

  void onCollisionDetected(Sprite hitObject) {
    if (!active) return;

    PVector normal = PVector.sub(this.position, hitObject.position);
    normal.normalize();
    float dotProduct = velocity.dot(normal);

    if (dotProduct < 0) {
      PVector reflection = PVector.mult(normal, 2 * dotProduct);
      velocity.sub(reflection);
    }

    position.add(PVector.mult(normal, 2));

    // Mark obstacle in path
    if (targetNode != null && path.size() > 0) {
      path.get(0).type = NodeType.OBSTACLE;
      path.clear(); // Replan
    }
  }


  void search() {
    // LRTA*: Make a single-step decision based on local information
    Node nextNode = LRTA_Nav.LRTA_step((Tank)this, currentNode, false);


    if (nextNode != null && nextNode != currentNode) {
      // Move to the chosen neighbor
      path.clear();
      path.add(nextNode);
      targetNode = nextNode;
      followPath();
    } else {
      println("Tank " + tank_id + ": LRTA* found no valid move!");
      tankState = TankState.STOP;
    }
  }
}
