class RadioMessage {
  Tank sender;
  PVector senderPos;
  PVector enemyPos;
  int senderHealth;
  int framesSent;        // för att räkna staleness

  RadioMessage(Tank sender, PVector enemyPos) {
    this.sender      = sender;
    this.senderPos   = sender.position.copy();
    this.enemyPos    = enemyPos.copy();
    this.senderHealth = sender.healthComponent.currentHealth;
    this.framesSent  = frameCount;
  }

  float staleness() {
    return (frameCount - framesSent) / 60.0; // sekunder
  }
}
