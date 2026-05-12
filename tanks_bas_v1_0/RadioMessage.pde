enum MessageType {
  SEEN_ENEMY, BEEN_HIT
}

class RadioMessage {



  Tank sender;
  PVector senderPos;
  MessageType messageType;
  PVector enemyPos;
  int senderHealth;
  int framesSent;        // för att räkna staleness

  RadioMessage(Tank sender, PVector enemyPos, MessageType messageType) {
    this.sender      = sender;
    this.senderPos   = sender.position.copy();
    this.enemyPos =
      (enemyPos != null)
      ? enemyPos.copy()
      : null;
    this.senderHealth = sender.healthComponent.currentHealth;
    this.framesSent  = frameCount;
    this.messageType = messageType;
  }

  float staleness() {
    return (frameCount - framesSent) / 60.0; // sekunder
  }
}
