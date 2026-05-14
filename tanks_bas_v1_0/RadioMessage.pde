//Asawin Sitthi assi7068
//Chris Pilegård chpi8651

enum MessageType {
  SEEN_ENEMY, BEEN_HIT
}

class RadioMessage {
  Tank sender;
  PVector senderPos;
  MessageType messageType;
  PVector enemyPos;
  int senderHealth;
  int framesSent; // frame då meddelandet skickades

  RadioMessage(Tank sender, PVector enemyPos, MessageType messageType) {
    this.sender = sender;
    this.senderPos = sender.position.copy();
    this.enemyPos = (enemyPos != null) ? enemyPos.copy() : null;
    this.senderHealth = sender.healthComponent.currentHealth;
    this.framesSent = frameCount;
    this.messageType = messageType;
  }

  /**
    @return Meddelandets ålder i sekunder
  */
  float staleness() {
    return (frameCount - framesSent) / frameRate; // sekunder
  }
}
