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
  int assignedResponders = 0; // Lägg till detta
  static final int MAX_RESPONDERS = 3;


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


  boolean needsMoreResponders() {
    return assignedResponders < MAX_RESPONDERS;
  }
}
