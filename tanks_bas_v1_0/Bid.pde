//Asawin Sitthi assi7068
//Chris Pilegård chpi8651

class Bid {
  Tank bidder;
  RadioMessage msg; // vilket uppdrag budet gäller
  float bidValue;

  Bid(Tank bidder, RadioMessage msg, float value) {
    this.bidder = bidder;
    this.msg = msg;
    this.bidValue = value;
  }
}