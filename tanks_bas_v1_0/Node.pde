class Node {
  // A node object knows about its location in the grid
  // as well as its size with the variables x,y,w,h
  float x, y;   // x,y location
  float w, h;   // width and height
  float angle; // angle for oscillating brightness

  PVector position;
  int col, row;

  Sprite content;
  NodeType type;
  Node parent;
  boolean visited;

  ArrayList<Node> neighbors;



    Node(float _posx, float _posy) {
    this.position = new PVector(_posx, _posy);
  }
  //***************************************************
  // Node Constructor
  // Denna används för temporära jämförelser mellan Node objekt.
  Node(int _id_col, int _id_row, float _posx, float _posy) {
    this.position  = new PVector(_posx, _posy);
    this.col       = _id_col;
    this.row       = _id_row;
    this.content   = null;
    this.type      = NodeType.EMPTY;
    this.neighbors = new ArrayList<Node>();
    this.w = 5; // ← FIX 1: was never initialized
    this.h = 5;
  }
  // Delete the addNeighbors() method entirely from Node — it doesn't belong here

  //***************************************************
  void addContent(Sprite s) {
    if (this.type == NodeType.EMPTY) {
      this.content = s;
      this.type = NodeType.OBSTACLE;
    }
  }

  //***************************************************
  boolean empty() {
    return this.type == NodeType.EMPTY;
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
          //n.neighbors.add(grid[checkCol][checkRow]);
        }
      }
    }
  }

  color getColor() {
      if (this.type == NodeType.EMPTY) {
        return color(0);
      } else if (this.type == NodeType.OBSTACLE) {
        return color(100);
      } else if (this.type == NodeType.HOME_BASE) {
        return color(255, 150, 150); 
      } else if (this.type == NodeType.ENEMY_BASE) {
        return color(150, 150, 255);
      }
      return color(0); // default
    }
}

  enum NodeType {
    EMPTY, OBSTACLE, HOME_BASE, ENEMY_BASE
  }

