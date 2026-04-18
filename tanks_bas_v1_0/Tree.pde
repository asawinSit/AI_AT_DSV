class Tree extends Sprite {

  static final float COLLISION_RADIUS = 165/2;
  static final String IMAGE_TREE = "tree01_v2.png";

  Tree(int posx, int posy) {
    this.img = loadImage(IMAGE_TREE);
    this.position = new PVector(posx, posy);
    this.diameter = this.img.width/2;
    this.radius = diameter/2;
    this.name = "tree";
  }

  void display() {
    pushMatrix();
    imageMode(CENTER);
    translate(this.position.x, this.position.y);

    fill(204, 102, 0, 100);
    int diameter = this.img.width/2;
    ellipse(0, 0, diameter, diameter);
    image(img, 0, 0);

    imageMode(CORNER);
    popMatrix();
  }

  void displayCollisionRadius() {
    pushStyle();
    noFill();
    stroke(255, 0, 0);
    strokeWeight(2);
    ellipse(this.position.x, this.position.y, COLLISION_RADIUS, COLLISION_RADIUS);
    popStyle();
  }
}