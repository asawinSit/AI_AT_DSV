
class ContractHandler {
  Tank owner;

  // Inbox
  ArrayList<RadioMessage> inbox = new ArrayList<>();

  // Kontrakt
  PVector contractedTarget = null;
  int contractFrames = 0;
  static final int CONTRACT_TIMEOUT = 300; // 5 sek

  ContractHandler(Tank owner) {
    this.owner = owner;
  }

  // --- Inbox ---
  void receiveMessage(RadioMessage msg) {
    if (msg.sender == owner) return;
    inbox.add(msg);
  }

  ArrayList<Bid> evaluateAndBid() {
    ArrayList<Bid> bids = new ArrayList<>();

    for (RadioMessage msg : inbox) {
      if (msg.staleness() > 3.0) continue;

      float value = computeHeuristic(msg);
      bids.add(new Bid(owner, msg, value));
    }

    inbox.clear();
    return bids;
  }

  float computeHeuristic(RadioMessage msg)
  {
    float distScore = 0;
    if (msg.messageType == MessageType.SEEN_ENEMY
      && msg.enemyPos != null)
    {
      distScore =
        1.0 / (1 + dist(
        owner.position.x,
        owner.position.y,
        msg.enemyPos.x,
        msg.enemyPos.y
        ));
    }

    float healthScore      = owner.healthComponent.currentHealth / 3.0;
    float busyPenalty      = hasContract() ? -0.5 : 0;
    float stalenessPenalty = msg.staleness() * 0.1;
    float enconterEnemyPenalty  = owner.enemyInSight() ? -0.5 : 0;

    return distScore + healthScore + busyPenalty + enconterEnemyPenalty - stalenessPenalty;
  }

  // --- Kontrakt ---
  boolean hasContract() {
    return contractedTarget != null;
  }

  boolean isTimedOut() {
    return contractFrames > CONTRACT_TIMEOUT;
  }

  void acceptContract(PVector target) {
    contractedTarget = target.copy();
    contractFrames   = 0;
    owner.path.clear();

    // Beräkna väg till målet direkt
    Node nearest = owner.nearestKnownNode(target);
    if (nearest != null) {
      println(owner.tank_id + " move to " + target);
      owner.computePathToNode(nearest);
    }

    owner.tankState = TankState.CONTRACTED;
  }

  void revokeContract() {
    contractedTarget = null;
    contractFrames   = 0;
    owner.path.clear();
    owner.tankState  = TankState.SEARCH;
  }

  // Anropas varje frame från Tank.update() när state == CONTRACTED
  void update() {
    contractFrames++;
  }
}
