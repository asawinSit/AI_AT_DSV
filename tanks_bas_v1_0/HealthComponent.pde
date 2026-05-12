class HealthComponent
{
  int currentHealth;
  int maxHealth;

  public HealthComponent(int maxHealth)
  {
    if (maxHealth <= 0)
    {
      throw new IllegalArgumentException("maxHealth must be > 0");
    }

    this.maxHealth = maxHealth;
    this.currentHealth = maxHealth;
  }

  public boolean takeDamage(int damage)
  {
    if (damage <= 0)
    {
      return false;
    }

    if (currentHealth <= 0)
    {
      return false;
    }

    currentHealth -= damage;

    if (currentHealth < 0)
    {
      currentHealth = 0;
    }
    return true;
  }

  public boolean isDead()
  {
    return currentHealth == 0;
  }

  public int getCurrentHealth()
  {
    return currentHealth;
  }

  public int getMaxHealth()
  {
    return maxHealth;
  }
}
