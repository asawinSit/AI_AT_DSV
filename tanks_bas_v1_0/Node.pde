enum NodeType {
  OBSTACLE, HOME_BASE, ENEMY_BASE, EMPTY
}

enum ExploredState {
  UNEXPLORED, VISITED, VISIBLE
}

class Node {
  PVector position;
  int col, row;
  float w = 5;
  float h = 5;
  
  NodeType type;
  ExploredState exploredState;

  ArrayList<Node> neighbors = new ArrayList<Node>();

  int distanceFromBase = Integer.MAX_VALUE;
  int cost;

  // Used in BFS
  Node parent;
  boolean visited;
  
  Node(int _id_col, int _id_row, float _posx, float _posy) {
    this.position = new PVector(_posx, _posy);
    this.col = _id_col;
    this.row = _id_row;
    this.type = NodeType.EMPTY;
    this.exploredState = ExploredState.UNEXPLORED;
  }

  boolean isTraversable() {
    return type != NodeType.OBSTACLE;
  }

  boolean isVisited() {
    return exploredState == ExploredState.VISITED;
  }

  boolean isVisible(){
    return exploredState == ExploredState.VISIBLE;
  }

  boolean isUnkown(){
    return exploredState == ExploredState.UNEXPLORED;
  }

  color getColor() {
      switch (type){
        case EMPTY:
          switch (exploredState){
            case VISITED: return color(150, 255, 150);
            case VISIBLE: return color(200, 220, 180, 160);
            default: return color(80,  80,  80,  120);
          }
        case OBSTACLE: return color(255, 0, 0);
        case HOME_BASE: return color(255, 150, 150);
        case ENEMY_BASE: return color(150, 150, 255);
        default: return color(0);
      }
    }
}