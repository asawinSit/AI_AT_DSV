class Node {
  // A node object knows about its location in the grid 
  // as well as its size with the variables x,y,w,h
  float x,y;   // x,y location
  float w,h;   // width and height
  float angle; // angle for oscillating brightness
  
  PVector position;
  int col, row;
  
  Sprite content;
  boolean isEmpty;
  boolean visited;
  Node parent;
  
  ArrayList<Node> neighbors;
  //***************************************************
  // Node Constructor 
  // Denna används för temporära jämförelser mellan Node objekt.
  Node(float _posx, float _posy) {
    this.position = new PVector(_posx, _posy);
  }

  //***************************************************  
  // Används vid skapande av grid
  Node(int _id_col, int _id_row, float _posx, float _posy) {
    this.position = new PVector(_posx, _posy);
    this.col = _id_col;
    this.row = _id_row;
    
    this.content = null;
    this.isEmpty = true;
  } 

  //***************************************************  
  Node(float tempX, float tempY, float tempW, float tempH, float tempAngle) {
    x = tempX;
    y = tempY;
    w = tempW;
    h = tempH;
    angle = tempAngle;
  } 

  //***************************************************  
  void addContent(Sprite s) {
    if (this.isEmpty) {
      this.content = s;  
    }
  }

  //***************************************************
  boolean empty() {
    return this.isEmpty;
  }
  
  //***************************************************
  Sprite content() {
    return this.content;
  }

  void addNeighbors(Node n) {
  for (int xOffset = -1; xOffset <= 1; xOffset++) {
    for (int yOffset = -1; yOffset <= 1; yOffset++) {
      // Skip the node itself (0,0 offset)
      if (xOffset == 0 && yOffset == 0) continue;
      
      // If you only want 4-way movement (no diagonals):
      // if (abs(xOffset) + abs(yOffset) > 1) continue;

      int checkCol = n.col + xOffset;
      int checkRow = n.row + yOffset;

      // Make sure the neighbor is inside the screen boundaries
      if (checkCol >= 0 && checkCol < cols && checkRow >= 0 && checkRow < rows) {
        n.neighbors.add(grid[checkCol][checkRow]);
      }
    }
  }
}
}