class Tank extends Sprite {

  PVector acceleration;
  PVector velocity;
  PVector position;


  PVector startpos;
  int tank_id;
  Team team;

  PImage img;
  color col;
  float diameter;

  float speed;
  float maxspeed;

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

    this.state        = 0; //0(still), 1(moving)
    this.speed        = velocity.mag();
    this.maxspeed     = 3;
    this.isInTransition = false;

    if (this.team.getId() == 0) this.heading = radians(0); // "0" radians.
    if (this.team.getId() == 1) this.heading = radians(180); // "3.14" radians.
  }

  //======================================
  void checkEnvironment() {
    println("*** Tank.checkEnvironment()");

    borders();
  }

  void checkForCollisions(Sprite sprite) {
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
      println("SPEED: " + this.speed);
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

    // 1. Find the angle to the target
    float angleToTarget = atan2(targetNode.position.y - position.y, targetNode.position.x - position.x);

    // 2. Calculate the difference
    float angleDiff = angleToTarget - heading;

    // 3. Normalize the angle (so it doesn't spin 300 degrees to turn 60)
    while (angleDiff < -PI) angleDiff += TWO_PI;
    while (angleDiff > PI) angleDiff -= TWO_PI;

    // 4. Rotate based on a fixed rotation speed
    float turnStep = 0.05;
    if (abs(angleDiff) > turnStep) {
      heading += (angleDiff > 0) ? turnStep : -turnStep;
    } else {
      heading = angleToTarget; // We are facing the target
    }
  }



  void stopMoving() {
    println("*** Tank.stopMoving()");

    // hade varit finare med animering!
    this.velocity.x = 0;
  }

  //======================================
  void action(String _action) {
    // println("*** Tank.action()");

    switch (_action) {
    case "search":
      turnToTarget();

      if (isFound == false) {
        targetNode = grid.getNearestNode(position);
        if (targetNode != null) {
          isFound = true;
        }
      } else
      {
        //state = 4; // Move state
      }

      // Only move forward if we are roughly facing the target
      if (targetNode != null) {
        float angleToTarget = atan2(targetNode.position.y - position.y, targetNode.position.x - position.x);
        if (abs(angleToTarget - heading) < 0.5) { // within ~30 degrees
          moveForward();
        }

        if (PVector.dist(position, targetNode.position) < 5) {
          isFound = true; // Target reached, search for a new one
        }
      }

      break;
    case "report":
      moveBackward();
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


  boolean isAtTarget() {
    if (targetNode == null) return false;
    return position.dist(targetNode.position) < 5; // within 5 pixels
  }



  void moveTo(Node node) {
    //println("*** Tank["+ this.getId() + "].moveTo(PVector)");

    this.targetNode = node;
  }


  void bfsSearch(Node startNode) {
    ArrayList<Node> queue = new ArrayList<Node>();

    startNode.visited = true;
    startNode.parent = null; // The start has no parent
    queue.add(startNode);

    while (queue.size() > 0) {
      Node current = queue.remove(0);

      if (isAtGoalNode(current)) {
        return; // Stop! We found the goal.
      }

      for (Node neighbor : current.neighbors) {
        // THE CRITICAL CHECK:
        if (!neighbor.visited) {
          neighbor.visited = true;
          neighbor.parent = current; // Link it back
          queue.add(neighbor);
        }
      }
    }
  }

  boolean isAtGoalNode(Node targetNode) {
    if (targetNode == null) return false;
    return position.dist(targetNode.position) < 5; // within 5 pixels
  }
}

