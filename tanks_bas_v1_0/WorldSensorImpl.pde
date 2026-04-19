class WorldSensorImpl implements WorldSensor {
  Grid grid;
  Tank[] allTanks = new Tank[6];

  WorldSensorImpl(Grid grid, Tank[] allTanks) {
    this.grid = grid;
    this.allTanks = allTanks;
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

  boolean senseTank(Tank self, float fromX, float fromY, float heading, float rayLength, float rayWidth) {
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
  }
}
