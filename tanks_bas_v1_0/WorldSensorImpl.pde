//Asawin Sitthi assi7068
//Chris Pilegård chpi8651
class WorldSensorImpl implements WorldSensor {
  Grid grid;
  Tank[] allTanks = new Tank[6];
  Team myTeam;
  Team enemyTeam;

  WorldSensorImpl(Grid grid, Tank[] allTanks, Team myTeam, Team enemyTeam ) {
    this.grid = grid;
    this.allTanks = allTanks;
    this.myTeam = myTeam;
    this.enemyTeam = enemyTeam;
  }

  NodeType senseTypeAt(int col, int row) {
    return grid.senseTypeAt(col, row);
  }

  boolean senseEnemyInRay(float fromX, float fromY, float heading, float rayLength, float rayWidth, int myTeamId) {
    PVector rayDir = new PVector(cos(heading), sin(heading));

    for (Tank t : allTanks) {
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
