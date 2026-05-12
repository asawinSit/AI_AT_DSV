//Asawin Sitthi assi7068
//Chris Pilegård chpi8651
class WorldSensorImpl implements WorldSensor {
  Grid grid;
  Tank[] allTanks = new Tank[6];
  Tree[] allTrees = new Tree[3];
  Team myTeam;
  Team enemyTeam;

  WorldSensorImpl(Grid grid, Tank[] allTanks, Team myTeam, Team enemyTeam, Tree[] allTrees) {
    this.grid = grid;
    this.allTanks = allTanks;
    this.allTrees = allTrees;
    this.myTeam = myTeam;
    this.enemyTeam = enemyTeam;
  }

  NodeType senseTypeAt(int col, int row) {
    return grid.senseTypeAt(col, row);
  }

  void updateObjectsInSight(
      Tank self,
      float fromX,
      float fromY,
      float heading,
      float viewDistance,
      float fovDegrees,
      int myTeamId
      ) {

    self.objectsInSight.get(ObjectType.ALLY).clear();
    self.objectsInSight.get(ObjectType.ENEMY).clear();
    self.objectsInSight.get(ObjectType.OBSTACLE).clear();

    PVector forward = PVector.fromAngle(heading);
    float halfFov = radians(fovDegrees * 0.5);

    // ---- Tanks ----
    for (Tank t : allTanks) {
      if (t == self) continue;

      PVector toTarget = new PVector(t.position.x - fromX, t.position.y - fromY);
      float distance = toTarget.mag();
      if (distance > viewDistance + t.radius) continue;

      toTarget.normalize();
      float angle = PVector.angleBetween(forward, toTarget);
      if (angle >= halfFov) continue;

      // *** Occlusion check ***
      if (isOccluded(fromX, fromY, t.position.x, t.position.y, t, null, self)) continue;

      if (t.isDead()) {
        self.objectsInSight.get(ObjectType.OBSTACLE).add(t.position.copy());
      } else if (t.team.getId() == myTeamId) {
        self.objectsInSight.get(ObjectType.ALLY).add(t.position.copy());
      } else {
        self.objectsInSight.get(ObjectType.ENEMY).add(t.position.copy());
      }
    }

    // ---- Trees ----
    for (Tree tree : allTrees) {
      PVector toTarget = new PVector(tree.position.x - fromX, tree.position.y - fromY);
      float distance = toTarget.mag();
      if (distance > viewDistance + tree.radius) continue;

      toTarget.normalize();
      float angle = PVector.angleBetween(forward, toTarget);
      if (angle >= halfFov) continue;

      // *** Occlusion check ***
      if (isOccluded(fromX, fromY, tree.position.x, tree.position.y, null, tree, self)) continue;

      self.objectsInSight.get(ObjectType.OBSTACLE).add(tree.position.copy());
    }
  }

  // Claude AI
  // Helper: does a ray from (rx,ry) to (tx,ty) get blocked by a circle at (cx,cy) with radius r?
  boolean rayBlockedByCircle(float rx, float ry, float tx, float ty,
                              float cx, float cy, float cr) {
    // Vector from ray origin to circle center
    float dx = cx - rx, dy = cy - ry;
    // Vector along the ray
    float lx = tx - rx, ly = ty - ry;
    float rayLen = sqrt(lx*lx + ly*ly);
    if (rayLen == 0) return false;

    // Project circle center onto ray (normalized)
    float t = (dx*lx + dy*ly) / (rayLen*rayLen);
    t = constrain(t, 0, 1); // Clamp to segment

    // Closest point on ray segment to circle center
    float closestX = rx + t*lx;
    float closestY = ry + t*ly;

    // Distance from circle center to closest point
    float distSq = (cx-closestX)*(cx-closestX) + (cy-closestY)*(cy-closestY);
    return distSq < cr*cr;
  }

  // Claude AI
  // Check if line-of-sight from (fromX,fromY) to (tx,ty) is blocked by any obstacle,
  // ignoring the specific tank/tree we're testing (skipTank / skipTree)
  boolean isOccluded(float fromX, float fromY, float tx, float ty,
                    Tank skipTank, Tree skipTree, Tank self) {
    // Check blocking by other tanks
    for (Tank blocker : allTanks) {
      if (blocker == self)     continue; // Never block with self
      if (blocker == skipTank) continue; // Don't block target with itself

      if (rayBlockedByCircle(fromX, fromY, tx, ty,
                            blocker.position.x, blocker.position.y, blocker.radius)) {
        // Only counts as a blocker if it's closer than the target
        float blockerDist = dist(fromX, fromY, blocker.position.x, blocker.position.y);
        float targetDist  = dist(fromX, fromY, tx, ty);
        if (blockerDist < targetDist) return true;
      }
    }

    // Check blocking by trees
    for (Tree blocker : allTrees) {
      if (blocker == skipTree) continue;

      if (rayBlockedByCircle(fromX, fromY, tx, ty,
                            blocker.position.x, blocker.position.y, blocker.radius)) {
        float blockerDist = dist(fromX, fromY, blocker.position.x, blocker.position.y);
        float targetDist  = dist(fromX, fromY, tx, ty);
        if (blockerDist < targetDist) return true;
      }
    }

    return false;
  }


  boolean senseEnemyInRay(float fromX, float fromY, float heading, float rayLength, float rayWidth, int myTeamId) {
    PVector rayDir = new PVector(cos(heading), sin(heading));

    for (Tank t : allTanks) {
      if (t.isDead())
        continue;
      if (t.team.getId() == myTeamId) continue;

      PVector toTank = new PVector(t.position.x - fromX, t.position.y - fromY);
      float along = toTank.dot(rayDir);
      if (along < 0 || along > rayLength + t.radius) continue;
      float perp = abs(toTank.x * rayDir.y - toTank.y * rayDir.x);
      if (perp < rayWidth * 0.5 + t.radius) return true;
    }
    return false;
  }

  /*   boolean senseTank(Tank self, float fromX, float fromY, float heading, float rayLength, float rayWidth) {
   PVector rayDir = new PVector(cos(heading), sin(heading));
   
   for (Tank t : allTanks) {
   if (t == self) continue;
   
   PVector toTank = new PVector(t.position.x - fromX, t.position.y - fromY);
   float along = toTank.dot(rayDir);
   if (along < 0 || along > rayLength + t.radius) continue;
   float perp = abs(toTank.x * rayDir.y - toTank.y * rayDir.x);
   if (perp < rayWidth * 0.5 + t.radius) return true;
   }
   return false;
   } */

  boolean isMoreThanHalfInsideABase(int myTeamId, Tank self)
  {
    Team team = null;
    if (myTeamId==myTeam.id) {
      team = myTeam;
    } else {
      team = enemyTeam;
    }
    if (team == null)
    {
      return false;
    }

    float hbX = team.homebase_x, hbY = team.homebase_y;
    float hbW = team.homebase_width, hbH = team.homebase_height;

    int inside = 0;
    int total = 16;

    for (int i = 0; i < total; i++) {
      float angle = TWO_PI * i / total;
      float px = self.position.x + cos(angle) * self.radius;
      float py = self.position.y + sin(angle) * self.radius;

      if (px >= hbX && px <= hbX + hbW &&
        py >= hbY && py <= hbY + hbH) {
        inside++;
      }
    }

    return inside >= total / 2;
  }

  PVector getBaseDirection(int myTeamId, Tank self) {

    Team team = (myTeamId == myTeam.id) ? myTeam : enemyTeam;
    if (team == null) return new PVector(0, 0);

    //Calculate the center of the base
    float centerX = team.homebase_x + (team.homebase_width / 2f);
    float centerY = team.homebase_y + (team.homebase_height / 2f);
    PVector baseCenter = new PVector(centerX, centerY);

    //Calculate direction: (Target - Current)
    PVector dir = PVector.sub(baseCenter, self.position());

    //Normalize so the vector length is 1 (useful for movement)
    dir.normalize();

    return dir;
  }
}
