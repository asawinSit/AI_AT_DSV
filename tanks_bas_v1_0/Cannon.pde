//Asawin Sitthi assi7068
//Chris Pilegård chpi8651

class Cannon{
  Tank owner;
  CannonBall cannonBall;

  int savedTime;
  int passedTime;
  int reloadTime = 3000; // millis
  boolean isReloading;
  boolean isLoaded;  // The shot is loaded and ready to shoot (visible on screen.)

  Cannon(Tank owner) {
    this.owner = owner;
    cannonBall = new CannonBall(this);
    this.cannonBall.setColor(owner.col);
    this.cannonBall.position = owner.position().copy();
    this.isLoaded = true;
    this.isReloading = false;
  }

  public void fire() {
    if (!isLoaded) return;

    PVector force = PVector.fromAngle(owner.heading);
    force.mult(10);
    this.cannonBall.isInMotion = true;
    this.cannonBall.applyForce(force);
    this.isLoaded = false;
    startTimer();
  }

  void display()
  {
    cannonBall.display();
  }

  void update() {
    if ( this.cannonBall.isInMotion) {
      cannonBall.update();
    } else {
      cannonBall.updateLoadedPosition(owner.position());
    }
    if (isReloading) {
      this.passedTime = millis() - this.savedTime;

      if (passedTime >= reloadTime) {
        reload();
      }
    }
  }

  void startTimer() {
    this.isReloading = true;
    this.savedTime = millis();
    this.passedTime = 0;
  }

  void resetTimer() {
    this.savedTime = 0;
    this.passedTime = 0;
  }

  void reload() {
    this.cannonBall.isInMotion = false;
    this.isLoaded = true;
    this.isReloading = false;
    this.cannonBall.velocity.set(0, 0, 0);
    this.cannonBall.acceleration.set(0, 0, 0);
    resetTimer();
  }

  void disable() {
    cannonBall.updateLoadedPosition(owner.position());
  }
}