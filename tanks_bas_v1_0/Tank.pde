enum TankState {
  SEARCH, REPORT, STOP
}

class Tank extends Sprite {

  // Physics
  PVector startpos;
  PVector acceleration;
  PVector velocity;
  float maxspeed = 3.0;
  float turnStep = 0.05;
  float heading;

  // Identity
  int tank_id;
  Team team;
  color col;

  // State
  TankState tankState;

  // sensor - Mabye change later
  // Only calls it for percieving what type is at a specific col or row
  Grid worldSensor;
  int cellSize; // Should the tank know this? Argument, tank team decision for accurate search.

  // own knowledge graph
  HashMap<String, Node> knownMap = new HashMap<String, Node>();

  // Navigation
  Node currentNode;
  Node lastNode;
  Node targetNode;
  ArrayList<Node> path = new ArrayList<Node>();
  PVector prevPosition; // Change to use lastNode.posiiton

  Tank(int id, Team team, PVector _startpos, float _size, color _col, Grid worldSensor, int cellSize) {
    this.tank_id      = id;
    this.diameter     = _size;
    this.radius       = diameter/2;
    this.col          = _col;
    this.team         = team;
    this.worldSensor  = worldSensor;
    this.startpos     = _startpos.copy();
    this.position     = _startpos.copy();
    this.prevPosition = _startpos.copy();
    this.velocity     = new PVector(0, 0);
    this.acceleration = new PVector(0, 0);
    this.tankState = TankState.STOP;
    this.cellSize = cellSize;

    if (this.team.getId() == 0) this.heading = radians(0);
    if (this.team.getId() == 1) this.heading = radians(180);
  }

  void addHomeBase(ArrayList<Node> homeBase) {
    for (Node n : homeBase) {
      String key = getPositionKey(n.col, n.row);
      if (!knownMap.containsKey(key)) {
        n.exploredState = ExploredState.VISIBLE;
        n.distanceFromBase = 0;
        knownMap.put(key, n);
      }
    }

    for (Node n : homeBase) wireNeighbours(n);

    currentNode = nearestKnownNode(position);
    lastNode = currentNode;

    currentNode.exploredState = ExploredState.VISITED;
    perceiveNeighbours();
  }

  void update() {
    if (this.tank_id != 1) return; // Endast tank0 i team0 uppdateras

    int col = worldToCol(position.x);
    int row = worldToRow(position.y);
    String key = getPositionKey(col, row);
    Node node = knownMap.containsKey(key) ? knownMap.get(key) : null;

    if (node != null && node != lastNode) {
      lastNode = currentNode;
      currentNode = node;
      currentNode.exploredState = ExploredState.VISITED;
      perceiveNeighbours();
    }

    switch (tankState) {
    case SEARCH:
      if (currentNode.type == NodeType.ENEMY_BASE) {
        println("Enemy base reached");
        tankState = TankState.REPORT;
      } else {
        search();
      }
      break;
    case REPORT:
      returnToBase();
      break;
    case STOP:
      stopMoving();
      break;
    }

    updatePosition();
    checkBoundaryCollision();
  }

  void search() {
    if (path.isEmpty()) {
      Node frontier = selectFrontierNode();
      if (frontier != null) {
        computePath(frontier);
      } else {
        println("No frontier found!");
        tankState = TankState.STOP;
      }
    }
    followPath();
  }

  void returnToBase() {
    if (path.isEmpty()) {
      computePathToFirstOf(NodeType.HOME_BASE);
    }
    followPath();
    if (path.isEmpty() && isMoreThanHalfInsideHomeBase()) {
      stopMoving();
      tankState = TankState.STOP;
    }
  }

  void computePathToFirstOf(NodeType goalType) {
    path.clear();
    if (currentNode == null) return;

    ArrayList<Node> touched = new ArrayList<Node>();
    ArrayList<Node> queue   = new ArrayList<Node>();

    currentNode.visited = true;
    currentNode.parent  = null;
    touched.add(currentNode);
    queue.add(currentNode);

    boolean found = false;
    Node    goal  = null;

    while (!queue.isEmpty()) {
      Node current = queue.remove(0);

      if (current.type == goalType && current != currentNode) {
        found = true;
        goal  = current;
        break;
      }

      for (Node nb : current.neighbors) {
        if (nb.visited) continue;
        if (!nb.isTraversable()) continue;
        if (nb.exploredState == ExploredState.UNEXPLORED) continue;

        nb.visited = true;
        nb.parent  = current;
        touched.add(nb);
        queue.add(nb);
      }
    }

    if (found) {
      Node step = goal;
      while (step != null && step != currentNode) {
        path.add(0, step);
        step = step.parent;
      }
    }

    for (Node n : touched) {
      n.visited = false;
      n.parent = null;
    }
  }

  void perceiveNeighbours() {
    if (currentNode == null) return;

    int[] colDirections = {-1, -1, -1, 0, 0, 1, 1, 1};
    int[] rowDirections = {-1, 0, 1, -1, 1, -1, 0, 1};

    for (int i = 0; i < 8; i++) {
      int nodeCol = currentNode.col + colDirections[i];
      int nodeRow = currentNode.row + rowDirections[i];
      String key = getPositionKey(nodeCol, nodeRow);

      if (!knownMap.containsKey(key)) {
        NodeType sensedType = worldSensor.senseTypeAt(nodeCol, nodeRow);

        float positionX = nodeCol * cellSize + cellSize;
        float posiitonY = nodeRow * cellSize + cellSize;
        Node newNode = new Node(nodeCol, nodeRow, positionX, posiitonY);
        newNode.type = sensedType;
        newNode.exploredState = ExploredState.VISIBLE;

        knownMap.put(key, newNode);
        wireNeighbours(newNode);
        computeDistanceFromBase(newNode);
      }
    }
  }

  void wireNeighbours(Node n) {
    int[] colDirections = {-1, -1, -1, 0, 0, 1, 1, 1};
    int[] rowDirections = {-1, 0, 1, -1, 1, -1, 0, 1};

    for (int i = 0; i < 8; i++) {
      String key = getPositionKey(n.col + colDirections[i], n.row + rowDirections[i]);
      if (knownMap.containsKey(key)) {
        Node nb = knownMap.get(key);
        if (!n.neighbors.contains(nb)) n.neighbors.add(nb);
        if (!nb.neighbors.contains((n))) nb.neighbors.add(n);
      }
    }
  }

  // BFS backwards from base nodes
  void computeDistanceFromBase(Node target) {
    ArrayList<Node> queue = new ArrayList<Node>();
    HashMap<Node, Integer> dist = new HashMap<Node, Integer>();

    for (Node n : knownMap.values()) {
      if (n.type == NodeType.HOME_BASE) { // Should be the base of the team so that enemies can use the same functionality
        dist.put(n, 0);
        queue.add(n);
      }
    }

    while (!queue.isEmpty()) {
      Node current = queue.remove(0);
      if (current == target) {
        target.distanceFromBase = dist.get(current);
        return;
      }
      for (Node nb : current.neighbors) {
        if (!dist.containsKey(nb) && nb.isTraversable()) {
          dist.put(nb, dist.get(current) + 1);
          queue.add(nb);
        }
      }
    }
  }

  Node selectFrontierNode() {
    ArrayList<Node> touched = new ArrayList<Node>();
    ArrayList<Node> queue = new ArrayList<Node>();
    ArrayList<Node> candidates = new ArrayList<Node>();

    for (Node n : knownMap.values()) {
      if (!n.visited) {

        touched.add(n);
        queue.add(n);
      }
    }

    while (!queue.isEmpty()) {
      Node current = queue.remove(0);

      for (Node nb : current.neighbors) {
        if (nb.visited) continue;
        nb.visited = true;
        touched.add(nb);

        if (!nb.isTraversable()) continue;
        if (nb.exploredState == ExploredState.UNEXPLORED) continue;

        if (nb.exploredState == ExploredState.VISIBLE) {
          candidates.add(nb);
        }
        queue.add(nb);
      }
    }

    for (Node n : touched) n.visited = false;
    if (candidates.isEmpty()) return null;

    Node bestNode = null;
    int bestScore = Integer.MAX_VALUE;
    for (Node n : candidates) {
      int score = 0;
      if (n.type != NodeType.HOME_BASE)
      {
        score  = n.distanceFromBase * 150;
      } else
      {
        score += 20000;
      }
      score += dist(position.x, position.y, n.position.x, n.position.y);
      if (n.exploredState == ExploredState.VISITED) score += 10000;
      if (score < bestScore) {
        bestScore = score;
        bestNode = n;
      }
    }

    return bestNode;
  }

  void computePath(Node goalNode) {
    path.clear();
    if (currentNode == null || goalNode == null) return;

    ArrayList<Node> touched = new ArrayList<Node>();
    ArrayList<Node> queue = new ArrayList<Node>();

    currentNode.visited = true;
    currentNode.parent = null;
    touched.add(currentNode);
    queue.add(currentNode);

    boolean found = false;

    while (!queue.isEmpty()) {
      queue.sort((a, b) -> Integer.compare(a.cost, b.cost));
      Node current = queue.remove(0);
      if (current == goalNode) {
        found = true;
        break;
      }

      for (Node nb : current.neighbors) {
        if (nb.visited) continue;
        if (!nb.isTraversable()) continue;

        int cost = current.cost + 1;

        if (nb.isVisible())
          cost -= 100;

        if (nb == lastNode)
          cost += 5;

        cost += nb.distanceFromBase;
        cost += dist(position.x, position.y, nb.position.x, nb.position.y);
        nb.cost = cost;
        nb.parent = current;
        nb.visited = true;

        touched.add(nb);
        queue.add(nb);
      }
    }

    if (found) {
      Node step = goalNode;
      while (step != null && step != currentNode) {
        path.add(0, step);
        step = step.parent;
      }
    }

    for (Node n : touched) {
      n.visited = false;
    }
  }

  void followPath() {
    if (path.isEmpty()) return;

    targetNode = path.get(0);
    turnToTarget();

    if (isLookingAtTarget()) {
      moveForward();
    } else {
      stopMoving();
    }

    if (isAtTarget()) {
      //position.set(targetNode.position);
      //stopMoving();
      path.remove(0);
      targetNode = path.isEmpty() ? null : path.get(0);
    }
  }

  void checkBoundaryCollision() {
    if (position.x > width-radius) {
      position.x = width-radius;
      velocity.x *= -1;
    } else if (position.x < radius) {
      position.x = radius;
      velocity.x *= -1;
    } else if (position.y > height-radius) {
      position.y = height-radius;
      velocity.y *= -1;
    } else if (position.y < radius) {
      position.y = radius;
      velocity.y *= -1;
    }
  }

  void onCollisionDetected(Sprite hitObject) {
    println("Collision detected");
    // Revert to last safe node position
    if (lastNode != null) {
      position.set(lastNode.position);
    } else {
      position.set(prevPosition);
    }
    velocity.mult(0);
    acceleration.mult(0);
    path.clear();          // force recompute of path around obstacle
    tankState = TankState.SEARCH;  // resume searching, not freezing
  }

  void moveForward() {
    PVector force = new PVector(cos(heading), sin(heading));
    force.mult(0.1);
    this.acceleration.add(force);
  }

  void turnToTarget() {
    if (targetNode == null) return;

    float angleToTarget = atan2(targetNode.position.y - position.y, targetNode.position.x - position.x);
    float angleDiff = angleToTarget - heading;

    while (angleDiff < -PI) angleDiff += TWO_PI;
    while (angleDiff > PI)  angleDiff -= TWO_PI;

    if (abs(angleDiff) > turnStep) {
      heading += (angleDiff > 0) ? turnStep : -turnStep;
    } else {
      heading = angleToTarget;
    }
  }

  boolean isLookingAtTarget() {
    if (targetNode == null) return false;

    float angleToTarget = atan2(targetNode.position.y - position.y, targetNode.position.x - position.x);
    float angleDiff = angleToTarget - heading;

    while (angleDiff < -PI) angleDiff += TWO_PI;
    while (angleDiff > PI)  angleDiff -= TWO_PI;

    float tolerance = turnStep * 0.5;
    return abs(angleDiff) < tolerance;
  }

  boolean isAtTarget() {
    if (targetNode == null) return false;
    return position.dist(targetNode.position) < 5; // within 5 pixels
  }


  void stopMoving() {
    velocity.mult(0);
    acceleration.mult(0);
  }

  void updatePosition() {

    this.prevPosition.set(this.position); // spara senaste pos.

    this.velocity.add(this.acceleration);
    this.velocity.limit(this.maxspeed);
    this.position.add(this.velocity);
    this.acceleration.mult(0);
  }

  //======================================
  void drawTank(float x, float y) {
    fill(this.col, 50);

    ellipse(x, y, 50, 50);
    strokeWeight(1);
    line(x, y, x+25, y);

    //kanontornet
    ellipse(0, 0, 25, 25);
    strokeWeight(3);
    float cannon_length = this.diameter/2;
    line(0, 0, cannon_length, 0);
  }

  void display() {
    fill(this.col);
    strokeWeight(1);

    pushMatrix();

    translate(this.position.x, this.position.y);

    imageMode(CENTER);

    rotate(this.heading);
    drawTank(0, 0);
    imageMode(CORNER);
    strokeWeight(1);
    // display tank position

    //fill(230);
    //rect(0+25, 0-25, 100, 40);
    //fill(30);
    // textSize(15);
    // text(this.name +"\n( " + this.position.x + ", " + this.position.y + " )", 25+5, -5-5);

    popMatrix();
  }

  String getPositionKey(int column, int row) {
    return column + "," + row;
  }

  int worldToCol(float positionX) {
    return (int)round((positionX - cellSize) / cellSize);
  }

  int worldToRow(float positionY) {
    return (int)round((positionY - cellSize) / cellSize);
  }

  Node nearestKnownNode(PVector pos) {
    Node bestNode = null;
    float bestDist = Float.MAX_VALUE;
    for (Node n : knownMap.values()) {
      float d = dist(pos.x, pos.y, n.position.x, n.position.y);
      if (d < bestDist) {
        bestDist = d;
        bestNode = n;
      }
    }
    return bestNode;
  }

  int getId() {
    return tank_id;
  }

  boolean isMoreThanHalfInsideHomeBase() {
    float hbX = team.homebase_x, hbY = team.homebase_y;
    float hbW = team.homebase_width, hbH = team.homebase_height;
    float threshold = radius * 0.5;
    return position.x > hbX + threshold
      && position.x < hbX + hbW - threshold
      && position.y > hbY + threshold
      && position.y < hbY + hbH - threshold;
  }

  boolean isMoreThanHalfInsideEnemyBase() {
    float ebX = width - 151, ebY = height - 351;
    float ebW = 150, ebH = 350;
    float threshold = radius * 0.5;
    return position.x > ebX + threshold
      && position.x < ebX + ebW - threshold
      && position.y > ebY + threshold
      && position.y < ebY + ebH - threshold;
  }
}
