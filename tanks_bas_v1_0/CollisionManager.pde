class CollisionManager {
  ArrayList<Sprite> objects = new ArrayList<Sprite>();

  void checkForCollisions() {
    // Standard for-loop is safest for nested checks
    for (int i = 0; i < objects.size(); i++) {
      Sprite a = objects.get(i);

      for (int j = i + 1; j < objects.size(); j++) {
        Sprite b = objects.get(j);

        if (isColliding(a, b)) {
          // If Sprite implements CollisionListener, notify them
          if (a instanceof CollisionListener) {
            ((CollisionListener)a).onCollisionDetected(b);
          }
          if (b instanceof CollisionListener) {
            ((CollisionListener)b).onCollisionDetected(a);
          }
        }
      }
    }
  }

  boolean isColliding(Sprite self, Sprite other ) {
    PVector distanceVect = PVector.sub(other.position, self.position);
    float distSq = distanceVect.magSq(); // (x2-x1)^2 + (y2-y1)^2
    float minDistance = self.radius + other.radius;

    return distSq < (minDistance * minDistance);
  }



  boolean isCollidingWithBoundary(Sprite self) {
    if ( self.position.x > width-self.radius) {
      self.position.x = width-self.radius;
      return true;
    } else if ( self.position.x <  self.radius) {
      self.position.x =  self.radius;
      return true;
    } else if ( self.position.y > height- self.radius) {
      self.position.y = height- self.radius;
      return true;
    } else if ( self.position.y <  self.radius) {
      self.position.y =  self.radius;
      return true;
    }
    return false;
  }

  void checkBoundaryCollision() {

    for (Sprite object : objects)
    {
      if (isCollidingWithBoundary(object))
      {
        object.onBoundaryCollisionDetected();
      }
    }
  }
}

interface BoundaryCollisionListener {
  void onBoundaryCollisionDetected();
}


interface CollisionListener {
  void onCollisionDetected(Sprite hitObject);
}
