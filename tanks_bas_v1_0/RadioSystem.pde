
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

    ArrayList<Bid> allBids = new ArrayList<>();
    for (Tank t : team.tanks) {
      if (!t.isDead()) {
        allBids.addAll(t.contractHandler.evaluateAndBid());
      }
    }

    for (RadioMessage announcement : pendingAnnouncements) {
      ArrayList<Bid> bidsForThis = new ArrayList<>();

      for (Bid bid : allBids) {
        if (bid.msg == announcement && bid.bidValue > 0) {
          bidsForThis.add(bid);
        }
      }

      // Sortera högst först
      bidsForThis.sort((a, b) -> Float.compare(b.bidValue, a.bidValue));

      // Tilldela till top 2-3 idle tanks
      int assigned = 0;
      for (Bid bid : bidsForThis) {
        if (assigned >= 2) break; // Max 2 tanks per target
        if (bid.bidder.contractHandler.hasContract()) continue; // Skippa upptagna

        if (announcement.messageType == MessageType.SEEN_ENEMY)
        {
          bid.bidder.contractHandler.acceptContract(announcement.enemyPos);
        } else {
          bid.bidder.contractHandler.acceptContract(announcement.senderPos);
        }
        assigned++;
      }
    }

    pendingAnnouncements.clear();
  }
}
