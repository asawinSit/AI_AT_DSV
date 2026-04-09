class Grid {
  int cols, rows;
  int grid_size;
  Node[][] nodes;

  //***************************************************  
  Grid(int _cols, int _rows, int _grid_size) {
    cols = _cols;
    rows = _rows;
    grid_size = _grid_size;
    nodes = new Node[cols][rows];

    createGrgetId();
  }

  //***************************************************  
  void createGrgetId() {

    for (int i = 0; i < cols; i++) {
      for (int j = 0; j < rows; j++) {
        // Initialize each object
        nodes[i][j] = new Node(i, j, i*grid_size+grid_size, j*grid_size+grid_size);
      }
    }

    for (int i = 0; i < cols; i++) {
    for (int j = 0; j < rows; j++) {
      addNeighbors(nodes[i][j]);
    }
  }
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
        n.neighbors.add(nodes[checkCol][checkRow]);
      }
    }
  }
}


  //***************************************************  
  void display() {
    for (int i = 0; i < cols; i++) {
      for (int j = 0; j < rows; j++) {
        // Initialize each object
        ellipse(nodes[i][j].position.x, nodes[i][j].position.y, 5.0, 5.0);
        //println("nodes[i][j].position.x: " + nodes[i][j].position.x);
        //println(nodes[i][j]);
      }
      //line(0, i*grid_size+grid_size, width, i*grid_size+grid_size);
    }
  }


  //***************************************************  
  Node getNearestNode(PVector pvec) {
    // En justering för extremvärden.
    float tempx = pvec.x;
    float tempy = pvec.y;
    if (pvec.x < 5) { 
      tempx=5;
    } else if (pvec.x > width-5) {
      tempx=width-5;
    }
    if (pvec.y < 5) { 
      tempy=5;
    } else if (pvec.y > height-5) {
      tempy=height-5;
    }

    pvec = new PVector(tempx, tempy);

    ArrayList<Node> nearestNodes = new ArrayList<Node>();

    for (int i = 0; i < cols; i++) {
      for (int j = 0; j < rows; j++) {
        if (nodes[i][j].position.dist(pvec) < grid_size) {
          nearestNodes.add(nodes[i][j]);
        }
      }
    }

    Node nearestNode = new Node(0, 0);
    for (int i = 0; i < nearestNodes.size(); i++) {
      if (nearestNodes.get(i).position.dist(pvec) < nearestNode.position.dist(pvec) ) {
        nearestNode = nearestNodes.get(i);
      }
    }

    return nearestNode;
  }

  // Node getNearestNodePosition(PVector pvec) {

  //  ArrayList<Node> nearestNodes = new ArrayList<Node>();

  //  for (int i = 0; i < cols; i++) {
  //    for (int j = 0; j < rows; j++) {
  //      if (nodes[i][j].position.dist(pvec) < grid_size) {
  //        nearestNodes.add(nodes[i][j]);      
  //      }
  //    }
  //  }

  //  Node nearestNode = new Node(0,0);
  //  for (int i = 0; i < nearestNodes.size(); i++) {
  //    if (nearestNodes.get(i).position.dist(pvec) < nearestNode.position.dist(pvec) ) {
  //      nearestNode = nearestNodes.get(i);
  //    }
  //  }

  //  return nearestNode;
  //}
  
  //***************************************************  
  PVector getNearestNodePosition(PVector pvec) {
    Node n = getNearestNode(pvec);
    
    return n.position;
  }

  //***************************************************  
  void displayNearestNode(PVector pvec) {

    PVector vec = getNearestNodePosition(pvec);
    ellipse(vec.x, vec.y, 5, 5);
  }

  //***************************************************  
  PVector getRandomNodePosition() {
    int c = int(random(cols));
    int r = int(random(rows));

    PVector rn = nodes[c][r].position;

    return rn;
  }
  
  //***************************************************
  // Används troligen tillsammans med getNearestNode().empty
  // om tom så addContent(Sprite)
  void addContent(Sprite s) {
    Node n = getNearestNode(s.position);
    n.addContent(s);
  }
  
}