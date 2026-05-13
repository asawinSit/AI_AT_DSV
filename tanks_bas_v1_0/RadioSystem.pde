class RadioSystem {
  static final int BID_COLLECTION_WINDOW = 10;
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

    // Collect all bids (including re-bids on current contracts)
    ArrayList<Bid> allBids = new ArrayList<>();
    for (Tank t : team.tanks) {
      if (!t.isDead()) {
        allBids.addAll(t.contractHandler.evaluateAndBid(pendingAnnouncements));
      }
    }
    // println("pendingAnnouncements.size() " + pendingAnnouncements.size());

    // Group bids by bidder to find each tank's best option
    HashMap<Tank, Bid> bestBidPerTank = new HashMap<>();
    for (Bid bid : allBids) {
      if (!bestBidPerTank.containsKey(bid.bidder) ||
        bid.bidValue > bestBidPerTank.get(bid.bidder).bidValue) {
        bestBidPerTank.put(bid.bidder, bid);
      }
    }

    // Award each tank its best contract
    for (Tank tank : bestBidPerTank.keySet()) {
      Bid winningBid = bestBidPerTank.get(tank);

      if (winningBid.bidValue >= MIN_SCORE_TO_WIN) {
        PVector target = (winningBid.msg.messageType == MessageType.SEEN_ENEMY)
          ? winningBid.msg.enemyPos
          : winningBid.msg.senderPos;

        tank.contractHandler.acceptContract(winningBid.msg, target, winningBid.bidValue);
        /*   println("Winner for task: " + winningBid.msg.messageType +
         " from " + winningBid.msg.sender.tank_id +
         " is " + tank.tank_id + " (score: " + winningBid.bidValue + ")"); */
      }
    }

    pendingAnnouncements.clear();
  }
}
