class GameManager
{
  boolean gameOver;
  Grid grid;

  GameManager(Grid grid)
  {
    gameOver = false;
    this.grid = grid;
  }

  boolean isGamOver()
  {
    return gameOver;
  }

  void setGamOver(boolean b)
  {
    gameOver = b;
  }
}
