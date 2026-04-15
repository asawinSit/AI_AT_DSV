class Tank extends Sprite {

  PVector acceleration;
  PVector velocity;

  PVector startpos;
  int tank_id;
  Team team;

  color col;
  float diameter;

  float speed;
  float maxspeed;

  float turnStep;

  float rotation;
  float rotationSpeed;
  float maxRotationSpeed;

  float heading;
  float targetHeading;

  float maxforce;

  int state;
  boolean isInTransition;

  boolean isFound;

  Node startNode;
  Node currentNode;
  Node targetNode;

  Node[][] nodes;


  //======================================
  Tank(int id, Team team, PVector _startpos, float _size, color _col ) {
    println("*** Tank.Tank()");
    this.tank_id      = id;
    this.diameter     = _size;
    this.col          = _col;
    this.team          = team;

    this.startpos     = new PVector(_startpos.x, _startpos.y);
    this.position     = new PVector(this.startpos.x, this.startpos.y);
    this.velocity     = new PVector(0, 0);
    this.acceleration = new PVector(0, 0);
    // At the end of Tank constructor:


    this.state        = 0; //0(still), 1(moving)
    this.speed        = velocity.mag();
    this.maxspeed     = 3;
    this.turnStep     = 0.05; // radians per update
    this.isInTransition = false;

    if (this.team.getId() == 0) this.heading = radians(0); // "0" radians.
    if (this.team.getId() == 1) this.heading = radians(180); // "3.14" radians.
  }

  //======================================
  void checkEnvironment() {
    println("*** Tank.checkEnvironment()");

    borders();
  }


boolean isColliding( PVector otherposition, float otherRadius) {

  float d = dist(position.x, position.y, otherposition.x, otherposition.y);
  return d < (tank_size/2 + otherRadius);
}


  void checkForCollisions(PVector vec) {
    checkEnvironment();
  }

  // Följande är bara ett exempel
  void borders() {
    float r = diameter/2;
    if (position.x < -r) position.x = width+r;
    if (position.y < -r) position.y = height+r;
    if (position.x > width+r) position.x = -r;
    if (position.y > height+r) position.y = -r;
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
  void action(String _action) {
    // println("*** Tank.action()");

    switch (_action) {
    case "search":

      moveTo(targetNode);

      turnToTarget();
      if (isLookingAtTarget()) {
        if (targetNode != null) moveForward();
      } else {
        stopMoving();
      }
      if (isAtGoalNode(targetNode)) {
        println("Reached target node at row " + targetNode.row + ", col " + targetNode.col);
        state = 4;
      }
      break;
    case "report":
      //moveBackward();
      break;
    case "turning":
      break;
    case "stop":
      stopMoving();
      break;
    }
  }

  //======================================
  //Här är det tänkt att agenten har möjlighet till egna val.

  void update() {
    // println("*** Tank.update()");
    if (this.tank_id != 1) return; // Endast tank0 i team0 uppdateras i detta exempel.

    switch (state) {
    case 0:
      // still/idle
      action("search");
      break;
    case 2:
      action("goBack");
      break;
    case 3:
      action("report");
      break;
    case 4:
      action("stop");

      break;
    }

    //this.position.add(velocity);
    speed = velocity.mag();
    updatePosition();
  }



  void updatePosition() {

    // this.positionPrev.set(this.position); // spara senaste pos.

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
    fill(230);
    rect(0+25, 0-25, 100, 40);
    fill(30);
    textSize(15);
    text(this.name +"\n( " + this.position.x + ", " + this.position.y + " )", 25+5, -5-5);

    popMatrix();
  }





  void moveTo(Node node) {
    //println("*** Tank["+ this.getId() + "].moveTo(PVector)");

    this.targetNode = node;
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
    moveTo(grid.getNearestNode(startpos));
  }
}
