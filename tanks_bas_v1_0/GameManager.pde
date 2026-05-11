class GameManager
{
  boolean gameOver;

  GameManager()
  {
    gameOver = false;
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
