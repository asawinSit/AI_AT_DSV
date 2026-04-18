class Sprite implements CollisionListener {

  PVector position;
  String name;
  float diameter, radius;
  PImage img;

  public String getName() {
    return name;
  }

  public float diameter() {
    return diameter;
  }

  public float getRadius() {
    return radius;
  }

  public PVector position() {
    return position;
  }

  public PImage getImage(){
    return img;
  }

  void onCollisionDetected(Sprite hitObject){}
}