enum TankState {
  SEARCH, REPORT, STOP
}

class Tank extends Sprite {

  // Physics
  PVector startpos;
  PVector acceleration;
  PVector velocity;
  float speed = 0;
  float maxSpeed = 3.0;
  float turnStep = 0.5;

  float maxForce = 0.1;

  // Identity
  int tank_id;
  Team team;
  color col;
  boolean active;

  // State
  TankState tankState;

  // Sensor
  WorldSensor worldSensor;
  int cellSize; // Should the tank know this? Argument, tank team decision for accurate search.
  float   rayLength  = 75;
  float   rayWidth;

  // own knowledge graph
  HashMap<String, Node> knownMap = new HashMap<String, Node>();

  // Navigation
  Node currentNode;
  Node lastNode;
  Node targetNode;

  Node lastTargetNode;
  ArrayList<Node> path = new ArrayList<Node>();

  int reportWaitFrames = 0;
  static final int REPORT_WAIT_DURATION = 180; // 3 seconds at 60fps

  Tank(int id, Team team, PVector _startpos, float _size, color _col) {
    this.tank_id      = id;
    this.diameter     = _size;
    this.radius       = diameter/2;
    this.col          = _col;
    this.team         = team;
    this.startpos     = _startpos.copy();
    this.position     = _startpos.copy();
    this.velocity     = new PVector(0, 0);
    this.acceleration = new PVector(0, 0);
    this.tankState = TankState.STOP;

    rayWidth   = radius /2;
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
    if (active != true) return;

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
    if (enemyInSight()) {
      println("Enemy detected");
    }

    switch (tankState) {
    case SEARCH:

      if (worldSensor.isMoreThanHalfInsideABase(69, this) && enemyInSight()) {
        path.clear();
        reportWaitFrames = 0;
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
    // Still travelling home
    if  ( currentNode.type != NodeType.HOME_BASE )
    {
      if (path.isEmpty())  computePathToNearestBase();
      followPath();
      return;
    }
    if  ( currentNode.type == NodeType.HOME_BASE && !worldSensor.isMoreThanHalfInsideABase(team.id, this))
    {
      PVector dir = worldSensor.getBaseDirection(team.id, this);

      dir.mult(maxSpeed);
      velocity = dir;
      return;
    } else if (worldSensor.isMoreThanHalfInsideABase(team.id, this))
    {
      stopMoving();
      reportWaitFrames++;
    }


    if (reportWaitFrames >= REPORT_WAIT_DURATION) {
      // Report complete — resume patrol
      println("Report Completed");
      reportWaitFrames = 0;
      path.clear();
      tankState = TankState.SEARCH;
    }
  }

  void computePathToNearestBase() {
    computePathTo(NodeType.HOME_BASE);
  }

  void computePathTo(NodeType goalType) {
    path.clear();
    if (currentNode == null) return;

    // Use a map to track the best known pixel-distance cost to each node
    HashMap<Node, Float> costSoFar = new HashMap<Node, Float>();
    ArrayList<Node> touched = new ArrayList<Node>();
    ArrayList<Node> queue   = new ArrayList<Node>();

    currentNode.parent  = null;
    costSoFar.put(currentNode, 0.0);
    touched.add(currentNode);
    queue.add(currentNode);

    boolean found = false;
    Node    goal  = null;

    while (!queue.isEmpty()) {
      // Sort by accumulated pixel distance — lowest cost first (Dijkstra)
      queue.sort((a, b) -> Float.compare(costSoFar.get(a), costSoFar.get(b)));
      Node current = queue.remove(0);

      if (current.type == goalType && current != currentNode) {
        found = true;
        goal  = current;
        break;
      }

      for (Node nb : current.neighbors) {
        if (!nb.isTraversable())                           continue;
        if (nb.exploredState == ExploredState.UNEXPLORED)  continue;

        // Pixel distance from current node to this neighbour
        float stepCost = dist(current.position.x, current.position.y,
          nb.position.x, nb.position.y);
        float newCost  = costSoFar.get(current) + stepCost;

        // Only add/update if we found a cheaper path to this neighbour
        if (!costSoFar.containsKey(nb) || newCost < costSoFar.get(nb)) {
          costSoFar.put(nb, newCost);
          nb.parent = current;
          if (!touched.contains(nb)) {
            touched.add(nb);
            queue.add(nb);
          }
        }
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
      if (n.type != NodeType.HOME_BASE) {
        score = n.distanceFromBase * 150;
      } else {
        score += 20000;
      }
      score += dist(position.x, position.y, n.position.x, n.position.y);
      if (n.exploredState == ExploredState.VISITED) score += 10000;

      if (n.exploredState == ExploredState.PENDING) score += 5000;

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

        if (nb.isVisible()) cost -= 100;
        if (nb == lastNode) cost += 5;
        if (nb.type == NodeType.HOME_BASE) cost += 1000;
        if (nb.exploredState == ExploredState.PENDING) cost += 10;

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
    lastTargetNode = targetNode;
    targetNode = path.get(0);

    seek();

    if (isAtTarget()) {
      path.remove(0);
      lastTargetNode = targetNode;

      targetNode = path.isEmpty() ? null : path.get(0);
    }
  }



  void onCollisionDetected(Sprite hitObject) {
    if (active) {

      PVector normal = PVector.sub(this.position, hitObject.position);
      normal.normalize();

      float dotProduct = velocity.dot(normal);

      // Only bounce if moving TOWARD the object (prevents getting stuck inside)
      if (dotProduct < 0) {
        PVector reflection = PVector.mult(normal, 2 * dotProduct);
        velocity.sub(reflection);
      }

      if (lastTargetNode != null) {
        lastTargetNode.exploredState = ExploredState.PENDING;
        path.clear();
      }
      position.add(PVector.mult(normal, 2));
    }
  }

  void onBoundaryCollisionDetected() {
    velocity.mult(-1);

    //energy loss
    velocity.mult(0.8);

    position.add(PVector.mult(velocity, 2));
  }


  boolean enemyInSight() {
    return worldSensor.senseEnemyInRay(
      position.x, position.y,
      this.velocity.heading(), rayLength, rayWidth,
      team.getId()
      );
  }

  //boolean tankInSight() {
  //  return worldSensor.senseTank(this,
  //    position.x, position.y,
  //    this.velocity.heading(), rayLength, rayWidth
  //    );
  //}


  void seek() {
    PVector desired = PVector.sub(targetNode.position, this.position);
    desired.setMag(this.maxSpeed);
    PVector steer = PVector.sub(desired, this.velocity);
    steer.limit(turnStep);
    this.applyForce(steer);
  }

  void applyForce(PVector force) {

    this.acceleration.add(force);
  }


  void updatePosition() {
    this.velocity.add(this.acceleration);
    this.velocity.limit(this.maxSpeed);
    float turnAmount = 0.001;
    velocity.mult(1.0 - constrain(turnAmount, 0, 0.7));
    this.position.add(this.velocity);
    this.acceleration.mult(0);

    // println("Speed:" + velocity.mag());
  }




  boolean isAtTarget() {
    if (targetNode == null) return false;
    return position.dist(targetNode.position) < radius; // within 5 pixels
  }


  void stopMoving() {
    velocity.mult(0);
    acceleration.mult(0);
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

    rotate(this.velocity.heading());
    drawTank(0, 0);
    imageMode(CORNER);
    strokeWeight(1);

    popMatrix();
  }

  void displaySightRay() {
    PVector rayDir  = new PVector(cos(this.velocity.heading()), sin(this.velocity.heading()));
    PVector perp    = new PVector(-sin(this.velocity.heading()), cos(this.velocity.heading()));

    // Ray tip
    float tipX = position.x + rayDir.x * rayLength;
    float tipY = position.y + rayDir.y * rayLength;

    // Colour changes when an enemy is detected
    boolean hit = enemyInSight();

    pushStyle();
    // Corridor sides
    stroke(hit ? color(255, 50, 50, 180) : color(255, 220, 0, 100));
    strokeWeight(1);
    noFill();

    // Left side of corridor
    line(position.x + perp.x * rayWidth, position.y + perp.y * rayWidth,
      tipX        + perp.x * rayWidth, tipY        + perp.y * rayWidth);

    // Right side of corridor
    line(position.x - perp.x * rayWidth, position.y - perp.y * rayWidth,
      tipX        - perp.x * rayWidth, tipY        - perp.y * rayWidth);

    // Cap at the end
    line(tipX + perp.x * rayWidth, tipY + perp.y * rayWidth,
      tipX - perp.x * rayWidth, tipY - perp.y * rayWidth);

    // Centre line
    stroke(hit ? color(255, 50, 50, 220) : color(255, 220, 0, 180));
    strokeWeight(1.5);
    line(position.x, position.y, tipX, tipY);

    // Filled corridor — semi-transparent
    fill(hit ? color(255, 50, 50, 50) : color(255, 220, 0, 40));
    noStroke();
    beginShape();
    vertex(position.x + perp.x * rayWidth, position.y + perp.y * rayWidth);
    vertex(tipX        + perp.x * rayWidth, tipY        + perp.y * rayWidth);
    vertex(tipX        - perp.x * rayWidth, tipY        - perp.y * rayWidth);
    vertex(position.x  - perp.x * rayWidth, position.y  - perp.y * rayWidth);
    endShape(CLOSE);
    popStyle();
  }

  void displayPath() {
    if (path.isEmpty()) return;
    pushStyle();

    // Draw all path nodes
    for (int i = 0; i < path.size(); i++) {
      Node n = path.get(i);

      if (i == path.size() - 1) {
        // Goal node — distinct colour
        fill(255, 80, 80, 200);
      } else {
        // Intermediate path nodes
        fill(80, 180, 255, 160);
      }
      ellipse(n.position.x, n.position.y, n.w * 3, n.h * 3);
    }

    // Draw the current target node (next step) on top
    if (targetNode != null) {
      fill(255, 200, 0, 200);
      ellipse(targetNode.position.x, targetNode.position.y, targetNode.w * 3, targetNode.h * 3);
    }
    popStyle();
  }

  void displayKnownMap(){
    for (Node n : knownMap.values()) {
      fill(n.getColor());
      ellipse(n.position.x, n.position.y, n.w, n.h);
    }
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
}
