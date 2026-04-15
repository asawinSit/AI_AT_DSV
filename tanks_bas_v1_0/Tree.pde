class Tree extends Sprite {


  //**************************************************
  Tree(int posx, int posy) {
    this.img = loadImage("tree01_v2.png");
    this.position = new PVector(posx, posy);
    this.diameter = this.img.width/2;
    this.radius = diameter/2;

    this.name = "tree";
  }

  //**************************************************
  void checkCollision(Tank other) {


    // Get distances between the balls components
    PVector distanceVect = PVector.sub(other.position, position);

    // Calculate magnitude of the vector separating the balls
    float distanceVectMag = distanceVect.mag();

    // Minimum distance before they are touching
    float minDistance = radius + other.radius;

    if (distanceVectMag < minDistance) {
      println("! collision med en tank [Tree]");
    }
  }

  //**************************************************
  void display() {
    imageMode(CENTER);
    pushMatrix();
    translate(this.position.x, this.position.y);

    fill(204, 102, 0, 100);
    int diameter = this.img.width/2;
    ellipse(0, 0, diameter, diameter);
    image(img, 0, 0);

    popMatrix();
    imageMode(CORNER);
  }

  void displayCollisionRadius() {
    pushStyle(); 
    noFill();
    stroke(255, 0, 0);
    strokeWeight(2);
    ellipse(this.position.x, this.position.y, 165/2, 165/2);
    popStyle();
  }
}
