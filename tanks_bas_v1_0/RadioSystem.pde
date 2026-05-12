class RadioSystem {
  static final int BID_COLLECTION_WINDOW = 2;
  Team team;
  ArrayList<RadioMessage> pendingAnnouncements = new ArrayList<>();
  int awardFrame = 0;
  static final float MIN_SCORE_TO_WIN = 0.15;

  RadioSystem(Team team) {
    this.team = team;
  }

  void announce(RadioMessage msg) {
    pendingAnnouncements.add(msg);
    for (Tank t : team.tanks) {
      if (!t.isDead()) {
        t.contractHandler.receiveMessage(msg);
      }
    }
    awardFrame = frameCount + BID_COLLECTION_WINDOW;
  }

  void update() {
    if (pendingAnnouncements.isEmpty()) return;
    if (frameCount < awardFrame) return;

    // Collect all bids (only above-threshold ones arrive here now)
    ArrayList<Bid> allBids = new ArrayList<>();
    for (Tank t : team.tanks) {
      if (!t.isDead()) {
        allBids.addAll(t.contractHandler.evaluateAndBid());
      }
    }

    for (RadioMessage announcement : pendingAnnouncements) {
      ArrayList<Bid> bidsForThis = new ArrayList<>();
      for (Bid bid : allBids) {
        if (bid.msg == announcement) {
          bidsForThis.add(bid);
        }
      }

      bidsForThis.sort((a, b) -> Float.compare(b.bidValue, a.bidValue));

      for (Bid bid : bidsForThis) {
        if (bid.bidValue < MIN_SCORE_TO_WIN) break; // sorted, so rest are worse
        PVector target = (announcement.messageType == MessageType.SEEN_ENEMY)
          ? announcement.enemyPos
          : announcement.senderPos;
        bid.bidder.contractHandler.acceptContract(target);
        println(" Winner for task: " + announcement.messageType + " from " + announcement.sender.tank_id + " is " + bid.bidder.tank_id);
      }
    }


    pendingAnnouncements.clear();
  }
}
