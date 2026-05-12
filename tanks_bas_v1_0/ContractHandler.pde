class ContractHandler {
  Tank owner;
  ArrayList<RadioMessage> inbox = new ArrayList<>();
  PVector contractedTarget = null;
  int contractFrames = 0;
  static final int CONTRACT_TIMEOUT = 300;

  // A tank bids if its personal score clears this bar.
  // Tune this: higher = fewer multi-assignments, lower = more.
  static final float BID_THRESHOLD = 0.4;

  ContractHandler(Tank owner) {
    this.owner = owner;
  }

  void receiveMessage(RadioMessage msg) {
    if (msg.sender == owner) return;
    inbox.add(msg);
  }

  // Returns a bid for every message whose heuristic clears the threshold.
  // No threshold: no bid. The RadioSystem never sees scores below the bar.
  ArrayList<Bid> evaluateAndBid() {
    ArrayList<Bid> bids = new ArrayList<>();
    for (RadioMessage msg : inbox) {
      if (msg.staleness() > 3.0) continue;
      float value = computeHeuristic(msg);
      if (value >= BID_THRESHOLD) {          // ← self-selection
        bids.add(new Bid(owner, msg, value));
      }
    }
    inbox.clear();
    return bids;
  }

  float computeHeuristic(RadioMessage msg) {
    float distScore = 0;
    if (msg.messageType == MessageType.SEEN_ENEMY && msg.enemyPos != null) {
      distScore = 1.0 / (1 + dist(
        owner.position.x, owner.position.y,
        msg.enemyPos.x,   msg.enemyPos.y
      ));
    }
    float healthScore       = owner.healthComponent.currentHealth / 3.0;
    float busyPenalty       = hasContract() ? -0.5 : 0;
    float stalenessPenalty  = msg.staleness() * 0.1;
    float encounterPenalty  = owner.enemyInSight() ? -0.5 : 0;
    return distScore + healthScore + busyPenalty + encounterPenalty - stalenessPenalty;
  }

  boolean hasContract() { return contractedTarget != null; }
  boolean isTimedOut()  { return contractFrames > CONTRACT_TIMEOUT; }

  void acceptContract(PVector target) {
    contractedTarget = target.copy();
    contractFrames   = 0;
    owner.path.clear();
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

  void update() {
    contractFrames++;
  }
}