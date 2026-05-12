class ContractNetProtocol
{
  ArrayList<RadioMessage> inbox = new ArrayList<>();
  PVector contractedTarget = null;                    // tilldelat mål
  int contractedFrame = 0;                            // när kontraktet sattes
  static final int CONTRACT_TIMEOUT = 300;            // 5 sek, häv om inget hänt

  ArrayList<RadioMessage> pendingAnnouncements = new ArrayList<>();
  ArrayList<Bid> pendingBids = new ArrayList<>();
  int awardFrame = 0;
  static final int BID_COLLECTION_WINDOW = 10; // frames att samla bud


  Tank owner;

  ContractNetProtocol(Tank owner)
  {
    this.owner = owner;
  }

  void receiveMessage( RadioMessage msg) {
    // Ignorera egna meddelanden
    if (msg.sender == owner) return;
    inbox.add(msg);
  }


  ArrayList<Bid> evaluateAndBid() {
    ArrayList<Bid> bids = new ArrayList<>();

    for (RadioMessage msg : inbox) {
      // Ignorera för gamla meddelanden
      if (msg.staleness() > 3.0) continue;

      float distScore   = 1.0 / (1 + dist(owner.position.x, owner.position.y,
        msg.enemyPos.x, msg.enemyPos.y));
      float healthScore = owner.healthComponent.currentHealth / 3.0;
      float busyPenalty = (owner.tankState == TankState.CONTRACTED) ? -0.5 : 0;
      float stalenessPenalty = msg.staleness() * 0.1;

      float value = distScore + healthScore + busyPenalty
        - stalenessPenalty;

      bids.add(new Bid(owner, msg, value));
    }

    inbox.clear();
    return bids;
  }

  void acceptContract(PVector target) {
    contractedTarget  = target.copy();
    contractedFrame   = frameCount;
    owner.tankState         = TankState.CONTRACTED;
    owner.path.clear();
  }

  void revokeContract() {
    contractedTarget = null;
    owner.tankState        = TankState.SEARCH;
    owner.path.clear();
  }



  /*   void receiveAnnouncement(RadioMessage msg) {
   pendingAnnouncements.add(msg);
   
   // Broadcast till alla levande tanks
   for (Tank t : owner.team.tanks) {
   if (!t.isDead()) {
   t.CNP.receiveMessage(msg);
   }
   }
   awardFrame = frameCount + BID_COLLECTION_WINDOW;
   } */

  void processBids() {
    if (pendingAnnouncements.isEmpty()) return;
    if (frameCount < awardFrame) return;

    // Samla bud från alla tanks
    ArrayList<Bid> allBids = new ArrayList<>();
    for (Tank t : owner.team.tanks) {
      if (!t.isDead()) {
        //allBids.addAll( t.CNP.evaluateAndBid());
      }
    }

    // För varje announcement, hitta högst budgivare
    for (RadioMessage announcement : pendingAnnouncements) {
      Tank winner = null;
      float bestValue = -Float.MAX_VALUE;

      for (Bid bid : allBids) {
        if (bid.msg == announcement && bid.bidValue > bestValue) {
          bestValue = bid.bidValue;
          winner    = bid.bidder;
        }
      }

      if (winner != null) {
        //winner.CNP.acceptContract(announcement.enemyPos);
      }
    }

    pendingAnnouncements.clear();
  }
}
