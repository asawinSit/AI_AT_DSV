interface WorldSensor {
  NodeType senseTypeAt(int col, int row);
  boolean senseEnemyInRay(float fromX, float fromY, float heading, float rayLength, float rayWidth, int myTeamId);

  boolean isMoreThanHalfInsideABase(int myTeamId, Tank self);


  PVector getBaseDirection(int myTeamId, Tank self);

  //boolean senseTank(Tank self, float fromX, float fromY, float heading, float rayLength, float rayWidth);
}
