//Asawin Sitthi assi7068
//Chris Pilegård chpi8651

class CannonBall extends Sprite{
  ArrayList<Particle> particles;

  PVector positionPrev;

  PVector velocity;
  PVector acceleration;

  boolean isInMotion;
  boolean isExploding;
  boolean isVisible;

  Cannon cannon;

  // Size radius
  float r = 8;

  color my_color;

  float topspeed = 10;

  CannonBall(Cannon cannon) {
    this.cannon = cannon;
    this.positionPrev = new PVector();
    this.position =  new PVector();
    this.velocity = new PVector();
    this.acceleration = new PVector();
    this.isInMotion = false;
    this.isVisible = true;
    this.radius = this.r;
    this.isExploding = false;
    this.name = "bullet";
  }

  void setColor(color c) {
    this.my_color = c;
  }

  PVector position() {
    return this.position;
  }

  void updateLoadedPosition(PVector pvec) {
    this.position.set(pvec);
    this.positionPrev.set(this.position);
    if (!this.isVisible) {
      this.isVisible = true;
    }
  }

  void applyForce(PVector force) {
    this.acceleration.add(force);
  }

  void displayExplosion() {
    this.isExploding = true;
    this.isVisible = false;
    this.isInMotion = false;
    this.particles = new ArrayList<Particle>();

    for (int i = 0; i < 20; i++) {
      this.particles.add(new Particle(this.position.copy()));
    }
  }

  void update() {
    if (this.isInMotion) {
      this.positionPrev.set(this.position);
      this.velocity.add(this.acceleration);
      this.velocity.limit(this.topspeed);
      this.position.add(this.velocity);
      this.acceleration.mult(0);
    }
  }

  void onCollisionDetected(Sprite hitObject) {
    if (isExploding) return;

    if (this.isInMotion) {
      if (hitObject != cannon.owner) {
        displayExplosion();
      }
    }
  }

  void onBoundaryCollisionDetected() {
    if (isExploding) return;
    displayExplosion();
  }

  void display() {
    imageMode(CENTER);
    stroke(0);
    strokeWeight(2);
    fill(this.my_color);

    // Draw explosion particles
    if (this.isExploding) {

      boolean allDead = true;

      for (Particle p : particles) {

        p.run();

        if (!p.isDead()) {
          allDead = false;
        }
      }

      // Explosion finished
      if (allDead) {
        this.isExploding = false;
      }
    } else {

      // Draw cannonball normally
      if (!(cannon.isReloading && !this.isInMotion) && this.isVisible) {

        pushMatrix();

        translate(this.position.x, this.position.y);
        ellipse(0, 0, this.r * 2, this.r * 2);

        popMatrix();
      }
    }

    // Reset drawing state
    fill(this.my_color);
    stroke(0);
    strokeWeight(1);
  }
}