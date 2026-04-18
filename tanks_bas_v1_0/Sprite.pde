class Sprite implements CollisionListener {

  PVector position;
  String name;
  float diameter, radius;
  PImage img;

  //**************************************************
  public String getName() {
    return this.name;
  }

  //**************************************************
  public float diameter() {
    return this.diameter;
  }

  //**************************************************
  public float getRadius() {
    return this.radius;
  }

  //**************************************************
  public PVector position() {
    return this.position;
  }



  void onCollisionDetected(Sprite hitObject)
  {
  }
}
