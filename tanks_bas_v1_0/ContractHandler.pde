//Asawin Sitthi assi7068
//Chris Pilegård chpi8651

/**
 ContractHandler, implementerar agentens roll i Contract Net Protocol.
 
 Enligt Russell & Norvig (2021) består protokollet av fyra faser:
 1. Problemidentifiering (problem recognition), görs i tank vid syn av fiende eller när tanken tar skada.
 2. Task announcement
 3. Budgivning (bidding)
 4. Tilldelning (awarding)
 
 Russell, S. & Norvig, P. (2021). Artificial Intelligence: A Modern Approach, Global Edition, 4th ed. Pearson. Kap.17.4 " Making Collective Decisions"
 */
class ContractHandler {
  static final float MOMENTUM_BONUS = 1.2; // Ge fördel åt nuvarande kontrakt vid omvärdering
  static final int CONTRACT_TIMEOUT = 300;

  Tank owner;
  ArrayList<RadioMessage> inbox = new ArrayList<>(); // inkommande task anouncements
  PVector contractedTarget = null; // positionen att åka till vid ett aktivt kontrakt
  RadioMessage currentContract = null;  // Det aktiva kontraktet (används för möjlig omvärdering vid fler kontrakt)
  int contractFrames = 0;

  ContractHandler(Tank owner) {
    this.owner = owner;
  }

  /**
   Tar emot en task announcement från RadioSystem (team) som är managern (igår i fas 2).
   Kommer från de andra tanksen i som ingår i team.
   */
  void receiveMessage(RadioMessage msg) {
    if (msg.sender == owner) return; // buda inte på sitt eget anouncement
    inbox.add(msg);
  }

  /**
   Utvärderar alla inkommande task anouncements och returnerar bud (fas 3).
   
   @return Lista med bud
   */
  ArrayList<Bid> evaluateAndBid() {
    ArrayList<Bid> bids = new ArrayList<>();

    // Om aktivt kontrakt, omvärdera nuvarande kontraktet med MOMENTUM_BONUS för fördel.
    if (hasContract()) {
      float currentScore = computeHeuristic(currentContract) * MOMENTUM_BONUS;
      bids.add(new Bid(owner, currentContract, currentScore));
    }

    // Utvärdera och buda på alla nya task announcements i inboxen.
    for (RadioMessage msg : inbox) {
      if (hasContract() && msg == currentContract) continue; // redan budgivit på denna ovan
      if (msg.staleness() > 3.0) continue; // Hoppa över gamla announcments
      float value = computeHeuristic(msg);
      bids.add(new Bid(owner, msg, value));
    }

    inbox.clear();
    return bids;
  }

  /**
   Beräknar agentens budvärde för ett givet uppdrag.
   
   Heuristiken väger samman:
   - distScore: nära mål är lättare att nå
   - healthScore: en skadad agent är sämre lämpad
   - stalenessPenalty: Avdrag för gammal information (osäker position)
   - stateMultiplier: Skalning baserat på agentens nuvarande tillstånd
   */
  float computeHeuristic(RadioMessage msg) {
    float distScore = 0;
    if (msg.messageType == MessageType.SEEN_ENEMY && msg.enemyPos != null) {
      distScore = 1.0 / (1 + dist(owner.position.x, owner.position.y, msg.enemyPos.x, msg.enemyPos.y));
    }
    float healthScore = owner.healthComponent.currentHealth / 3.0;
    float stalenessPenalty = msg.staleness() * 0.1;
    float rawScore = distScore + healthScore - stalenessPenalty;

    return rawScore * stateMultiplier();
  }

  /**
   @return En skalningsfaktor baserat på agentens nuvarande tillstånd
   */
  float stateMultiplier() {
    switch (owner.tankState) {
    case SEARCH:
      return 1.0; // Fullt tillgänglig
    case CONTRACTED:
      return 0.3; // Delvis tillgänglig, kan byta om nytt uppdrag är mycket bättre
    case AIM:
      return 0.1; // Nästen ej tillgänglig
    case SHOOT:
      return 0.0; // Ej tillgänglig
    default:
      return 0.0;
    }
  }

  /**
   Agenten accepterar ett tilldelat kontrakt från RadioSystem (manager - team) och blit en "contractor" (ingår i fas 4).
   
   Agenten planerar om sin väg för att ta sig till målet av kontraktet och sätter sitt state till CONTRACTED.
   */
  void acceptContract(RadioMessage msg, PVector target, float bidValue) {
    boolean isSwitching = (currentContract != null && currentContract != msg); // Byter uppdrag? (För print)

    currentContract = msg;
    contractedTarget = target.copy();

    // Planera ny väg till kontraktmålet
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

  /**
   Avbryter det nuvarande kontraktet och återställer agenten till sökläge.
   */
  void revokeContract() {
    contractedTarget = null;
    currentContract = null;
    owner.path.clear();
    owner.tankState = TankState.SEARCH;
  }

  boolean hasContract() {
    return currentContract != null;
  }

  boolean isTimedOut() {
    return contractFrames > CONTRACT_TIMEOUT;
  }

  void update() {
    contractFrames++; // Räkna frames för timeout-kontroll
  }
}
