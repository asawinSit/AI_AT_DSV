class ContractHandler {
  Tank owner;
  ArrayList<RadioMessage> inbox = new ArrayList<>();
  PVector contractedTarget = null;
  int contractFrames = 0;
  static final int CONTRACT_TIMEOUT = 300;

  // A tank bids if its personal score clears this bar.
  // Tune this: higher = fewer multi-assignments, lower = more.


  ContractHandler(Tank owner) {
    this.owner = owner;
  }

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


  float computeHeuristic(RadioMessage msg) {
    float distScore = 0;
    if (msg.messageType == MessageType.SEEN_ENEMY && msg.enemyPos != null) {
      distScore = 1.0 / (1 + dist(
        owner.position.x, owner.position.y,
        msg.enemyPos.x, msg.enemyPos.y
        ));
    }
    float healthScore      = owner.healthComponent.currentHealth / 3.0;
    float stalenessPenalty = msg.staleness() * 0.1;
    float rawScore         = distScore + healthScore - stalenessPenalty;

    return rawScore * stateMultiplier();  // state scales the whole score
  }


  float stateMultiplier() {
    switch (owner.tankState) {
    case SEARCH:
      return 1.0;
    case CONTRACTED:
      return 0.3;
    case AIM:
      return 0.1;
    case SHOOT:
      return 0.0;
    default:
      return 0.0;
    }
  }


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
    Node nearest = owner.nearestKnownNode(target);
    if (nearest != null) {
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
