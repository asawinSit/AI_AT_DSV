class ContractHandler {
  Tank owner;
  ArrayList<RadioMessage> inbox = new ArrayList<>();
  PVector contractedTarget = null;
  RadioMessage currentContract = null;  // NEW: track the message for re-evaluation
  float currentContractValue = 0;        // NEW: track current contract's value
  int contractFrames = 0;
  static final int CONTRACT_TIMEOUT = 300;
  static final float MOMENTUM_BONUS = 1.2;  // NEW: bonus for sticking with current task

  ContractHandler(Tank owner) {
    this.owner = owner;
  }

  void receiveMessage(RadioMessage msg) {
    if (msg.sender == owner) return;
    inbox.add(msg);
  }

  ArrayList<Bid> evaluateAndBid() {
    ArrayList<Bid> bids = new ArrayList<>();

    // Re-bid on current contract if we have one
    if (hasContract() && currentContract != null) {
      float currentScore = computeHeuristic(currentContract) * MOMENTUM_BONUS;
      bids.add(new Bid(owner, currentContract, currentScore));
    }

    // Bid on all new messages in inbox
    for (RadioMessage msg : inbox) {
      // Skip if this is our current contract (already bid on it above)
      if (currentContract != null && msg == currentContract) continue;

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

    return rawScore * stateMultiplier();
  }

  float stateMultiplier() {
    switch (owner.tankState) {
    case SEARCH:
      return 1.0;
    case CONTRACTED:
      return 0.3;  // Still willing to switch if new task is much better
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

  void acceptContract(RadioMessage msg, PVector target, float bidValue) {
    // Check if we're switching contracts
    boolean isSwitching = (currentContract != null && currentContract != msg);

    currentContract = msg;
    contractedTarget = target.copy();
    currentContractValue = bidValue;
    contractFrames = 0;

    owner.path.clear();
    Node nearest = owner.nearestKnownNode(target);
    if (nearest != null) {
      owner.computePathToNode(nearest);
    }
    owner.tankState = TankState.CONTRACTED;

    if (isSwitching) {
      println("Tank " + owner.tank_id + " switched contracts (new score: " + bidValue + ")");
    }
  }

  void revokeContract() {
    contractedTarget = null;
    currentContract = null;
    currentContractValue = 0;
    contractFrames = 0;
    owner.path.clear();
    owner.tankState = TankState.SEARCH;
  }

  void update() {
    contractFrames++;
  }
}
