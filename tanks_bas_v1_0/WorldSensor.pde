interface WorldSensor{
    NodeType senseTypeAt(int col, int row);
    boolean senseEnemyInRay(float fromX, float fromY, float heading, float rayLength, float rayWidth, int myTeamId);
}