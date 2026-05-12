class CannonBall extends Sprite
{
  ArrayList<Particle> particles;

  PVector positionPrev; //spara temp senaste pos.

  PVector velocity;
  PVector acceleration;

  boolean isInMotion; // The shot is on its way.
  boolean isExploding;
  boolean isVisible;

  Cannon cannon;

  // Size
  float r = 8;

  color my_color;

  float topspeed = 10;

  //**************************************************
  CannonBall(Cannon cannon) {
    //println("New CannonBall()");
    this.cannon = cannon;
    this.positionPrev = new PVector();
    this.position =  new PVector();
    this.velocity = new PVector();
    this.acceleration = new PVector();
    this.isInMotion = false;
    this.isVisible = true;

    //this.diameter = this.img.width/2;
    this.radius = this.r;
    this.isExploding = false;

    this.name = "bullet";
  }

  //**************************************************
  void setColor(color c) {
    this.my_color = c;
  }
  PVector position() {
    return this.position;
  }

  //**************************************************
  // Called by tank object.
  void updateLoadedPosition(PVector pvec) {
    //println("*** CannonBall.updateLoadedPosition()");

    this.position.set(pvec);
    this.positionPrev.set(this.position);
    if (!this.isVisible) {
      this.isVisible = true;
    }
  }


  //**************************************************
  // Called by tank object, when shooting.
  void applyForce(PVector force) {
    this.acceleration.add(force);
  }



  //**************************************************
  void displayExplosion() {

    this.isExploding = true;
    this.isVisible = false;
    this.isInMotion = false;

    this.particles = new ArrayList<Particle>();

    // Spawn particles at cannonball world position
    for (int i = 0; i < 20; i++) {
      this.particles.add(new Particle(this.position.copy()));
    }
  }

  //**************************************************
  void update() {
    if (this.isInMotion) {
      this.positionPrev.set(this.position); // spara senaste pos.

      this.velocity.add(this.acceleration);
      this.velocity.limit(this.topspeed);
      this.position.add(this.velocity);
      this.acceleration.mult(0);
    }
  }

  void onCollisionDetected(Sprite hitObject) {
    if (isExploding)
      return;
    if (this.isInMotion) {

      if (hitObject != cannon.owner) {
        displayExplosion();
      }
    }
  }

  void onBoundaryCollisionDetected()
  {
    if (isExploding)
      return;
    displayExplosion();
  }

  //**************************************************
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
