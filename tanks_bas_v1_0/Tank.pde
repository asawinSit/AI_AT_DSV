enum TankState{
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
  float targetHeading;

  // Identity
  int tank_id;
  Team team;
  color col;

  // State
  TankState tankState;

  // Navigation
  Node startNode;
  Node currentNode;
  Node targetNode;
  ArrayList<Node> knownNodes = new ArrayList<Node>();
  ArrayList<Node> path = new ArrayList<Node>();
  PVector prevPosition;

  Tank(int id, Team team, PVector _startpos, float _size, color _col ) {
    println("*** Tank.Tank()");
    this.tank_id      = id;
    this.diameter     = _size;
    this.radius = diameter/2;
    this.col          = _col;
    this.team          = team;

    this.startpos     = _startpos.copy();
    this.position     = _startpos.copy();
    this.prevPosition = _startpos.copy();
    this.velocity     = new PVector(0, 0);
    this.acceleration = new PVector(0, 0);
    
    this.tankState = TankState.STOP;

    if (this.team.getId() == 0) this.heading = radians(0);
    if (this.team.getId() == 1) this.heading = radians(180);
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

  void onCollisionDetected(Sprite hitObject)
  {
    println("collide");
    position.set(this.prevPosition);
    tankState = TankState.STOP;
  }

  void moveForward() {
    //println("*** Tank[" + getId() + "].moveForward()");

    // Offset the angle since we drew the ship vertically
    float angle = this.heading; // - PI/2;
    // Polar to cartesian for force vector!
    PVector force = new PVector(cos(angle), sin(angle));
    force.mult(0.1);
    if (this.tank_id == 1)
    {
      println(targetNode.row + " " + targetNode.col);
    }

    applyForce(force);
  }

  void applyForce(PVector force) {
    this.acceleration.add(force);
  }


  void moveBackward() {
    // println("*** Tank.moveBackward()");

    if (this.velocity.x > -this.maxspeed) {
      this.velocity.x -= 0.01;
    } else {
      this.velocity.x = -this.maxspeed;
    }
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

    // Use half the turnStep as tolerance — tight enough to look accurate,
    // loose enough that the tank never stutters at the threshold
    float tolerance = turnStep * 0.5;
    return abs(angleDiff) < tolerance;
  }


  void stopMoving() {
    println("*** Tank.stopMoving()");

    // hade varit finare med animering!
    this.velocity.x = 0;
    this.velocity.y = 0;
  }

  //======================================
  //Här är det tänkt att agenten har möjlighet till egna val.

  void update() {
    // println("*** Tank.update()");
    if (this.tank_id != 1) return; // Endast tank0 i team0 uppdateras i detta exempel.

    switch (tankState) {
    case SEARCH:
      turnToTarget();
      if (isLookingAtTarget()) {
        if (targetNode != null) moveForward();
      } else {
        stopMoving();
      }
      if (isAtGoalNode(targetNode)) {
        println("Reached target node at row " + targetNode.row + ", col " + targetNode.col);
        tankState = TankState.STOP;
      }
      break;
    case REPORT: break;
    case STOP:
      if (velocity.x > 0 || velocity.y > 0){
        stopMoving();
      }
      break;
    }

    updatePosition();
    checkBoundaryCollision();
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

  void setTargetNode(Node node) {
    targetNode = node;
  }

  void bfsSearch(Node startNode) {
    if (startNode == null) {           // ← guard: currentNode wasn't set yet
      currentNode = grid.getNearestNode(position);
      if (currentNode == null) return; // grid not ready
      startNode = currentNode;
    }

    grid.resetVisited();
    ArrayList<Node> queue = new ArrayList<Node>();
    startNode.visited = true;
    startNode.parent  = null;
    queue.add(startNode);

    while (queue.size() > 0) {
      Node current = queue.remove(0);
      if (isAtGoalNode(current))
      {
        //targetNode = current;
        return;
      }

      for (Node neighbor : current.neighbors) {
        if (!neighbor.visited) {
          neighbor.visited = true;
          neighbor.parent  = current;
          queue.add(neighbor);
        }
      }
    }
  }

  void followPath(Node goalNode) {
    if (goalNode == null || !goalNode.visited) return;

    // Walk back from goal to find the first step after currentNode
    Node step = goalNode;
    while (step.parent != null && step.parent != currentNode) {
      step = step.parent;
    }

    targetNode = step;   // turnToTarget() + moveForward() will do the rest
    turnToTarget();
    if (targetNode != null) moveForward();

    // Advance currentNode when we arrive
    if (isAtTarget()) {
      currentNode = targetNode;
      targetNode  = null;
      stopMoving();
    }
  }

  boolean isAtGoalNode(Node targetNode) {
    if (targetNode == null) return false;
    return position.dist(targetNode.position) < 5; // within 5 pixels
  }

  boolean isAtTarget() {
    if (targetNode == null) return false;
    return position.dist(targetNode.position) < 5; // within 5 pixels
  }


  void goBackToBase() {
    setTargetNode(grid.getNearestNode(startpos));
  }

  
}
