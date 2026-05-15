//Asawin Sitthi assi7068
//Chris Pilegård chpi8651

/**
 RadioSystem, implementerar "managern" i Contract Net Protocol.
 
 RadioSystem ansvarar för:
 1. Annonsering av uppgifter (task announcement) till alla levande teammedlemmar
 2. Insamling av bud (bid collection)
 3. Tilldelning av kontrakt till bäst lämpade agent(er) (award)
 
 Russell, S. & Norvig, P. (2021). Artificial Intelligence: A Modern Approach, Global Edition, 4th ed. Pearson. Kap.17.4 " Making Collective Decisions"
 */
class RadioSystem {
  static final float MIN_SCORE_TO_WIN = 0.15;

  Team team;
  ArrayList<RadioMessage> pendingAnnouncements = new ArrayList<>(); // används för att undvika att be om bud när det inte finns något att buda på

  RadioSystem(Team team) {
    this.team = team;
  }

  /**
   Sänder ut task announcement till alla levande tanks som tillhör detta team (ingår i fas 2, se ContractHandler).
   */
  void announce(RadioMessage msg) {
    pendingAnnouncements.add(msg);
    for (Tank t : team.tanks) {
      if (!t.isDead() && msg.sender != t && t.comunication_Imp == Comunication_Imp.CNP) {
        t.contractHandler.receiveMessage(msg);
      }
    }
  }

  /**
   Samlar in bud och tilldelar kontrakt, körs varje frame. Ingår i fas 3 och 4 (se ContractHandler), men ur managerns persektiv.
   
   Varje tank tilldelas sitt bästa kontrakt (kan vara samma uppgift eller olika uppgifter).
   */
  void update() {
    if (pendingAnnouncements.isEmpty()) return; // Finns ingenting att buda på denna frame.

    // Samla in bud från alla levande agenter i detta team.
    ArrayList<Bid> allBids = new ArrayList<>();
    for (Tank t : team.tanks) {
      if (!t.isDead()) {
        allBids.addAll(t.contractHandler.evaluateAndBid());
      }
    }

    // Hitta det högsta värderade budet per agent, En agent kan bara vinna ett kontrakt åt gången
    HashMap<Tank, Bid> bestBidPerTank = new HashMap<>();
    for (Bid bid : allBids) {
      if (!bestBidPerTank.containsKey(bid.bidder) ||
        bid.bidValue > bestBidPerTank.get(bid.bidder).bidValue) {
        bestBidPerTank.put(bid.bidder, bid);
      }
    }

    // Tilldela kontrakt
    for (Tank tank : bestBidPerTank.keySet()) {
      Bid winningBid = bestBidPerTank.get(tank);

      // Kräv minimivärde för tilldelning, undvik att skicka ej kapabla agenter.
      if (winningBid.bidValue >= MIN_SCORE_TO_WIN) {
        PVector target = (winningBid.msg.messageType == MessageType.SEEN_ENEMY) ? winningBid.msg.enemyPos : winningBid.msg.senderPos;

        // Notifiera vinnare att acceptera uppdrag.
        tank.contractHandler.acceptContract(winningBid.msg, target, winningBid.bidValue);

        /*   println("Winner for task: " + winningBid.msg.messageType +
         " from " + winningBid.msg.sender.tank_id +
         " is " + tank.tank_id + " (score: " + winningBid.bidValue + ")"); */
      }
    }
    pendingAnnouncements.clear();
  }
}
