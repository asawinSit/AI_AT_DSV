class RadioSystem {
  static final int BID_COLLECTION_WINDOW = 10;
  Team team;
  ArrayList<RadioMessage> pendingAnnouncements = new ArrayList<>();
  int awardFrame = 0;

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

      // Award to every tank that bid on this message.
      // The threshold already filtered out bad fits; we just enforce the cap.
      for (Bid bid : allBids) {
        if (bid.msg != announcement) continue;
        if (!announcement.needsMoreResponders()) break;  // cap hit

        PVector target = (announcement.messageType == MessageType.SEEN_ENEMY)
          ? announcement.enemyPos
          : announcement.senderPos;

        bid.bidder.contractHandler.acceptContract(target);
        announcement.assignedResponders++;
      }
    }

    pendingAnnouncements.clear();
  }
}