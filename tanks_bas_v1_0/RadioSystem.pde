
class RadioSystem {
    
  static final int BID_COLLECTION_WINDOW = 10;
  Team team;
  ArrayList<RadioMessage> pendingAnnouncements = new ArrayList<>();
  int awardFrame = 0;

  RadioSystem(Team team) {
    this.team = team;
  }

  // Tank anropar denna när den ser en fiende
  void announce(RadioMessage msg) {
    pendingAnnouncements.add(msg);

    // Broadcast till alla levande tanks utom sändaren
    for (Tank t : team.tanks) {
      if (!t.isDead()) {
        t.contractHandler.receiveMessage(msg);
      }
    }
    awardFrame = frameCount + BID_COLLECTION_WINDOW;
  }

  // Anropas varje frame från Team.update()
  void update() {
    if (pendingAnnouncements.isEmpty()) return;
    if (frameCount < awardFrame) return;

    // Samla bud från alla tanks
    ArrayList<Bid> allBids = new ArrayList<>();
    for (Tank t : team.tanks) {
      if (!t.isDead()) {
        allBids.addAll(t.contractHandler.evaluateAndBid());
      }
    }

    // För varje announcement, hitta högst budgivare
    for (RadioMessage announcement : pendingAnnouncements) {
      Tank winner   = null;
      float bestVal = -Float.MAX_VALUE;

      for (Bid bid : allBids) {
        if (bid.msg == announcement && bid.bidValue > bestVal) {
          bestVal = bid.bidValue;
          winner  = bid.bidder;
        }
      }

      if (winner != null) {
        winner.contractHandler.acceptContract(announcement.enemyPos);
      }
    }

    pendingAnnouncements.clear();
  }
}
