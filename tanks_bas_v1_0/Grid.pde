class Grid {
  int cols, rows;
  int grid_size;
  Node[][] nodes;

  Grid(int _cols, int _rows, int _grid_size) {
    cols = _cols;
    rows = _rows;
    grid_size = _grid_size;
    nodes = new Node[cols][rows];

    createGrid();
  }

  Node getNode(int row, int col)
  {
    return nodes[row][col];
  }

  Node getRandomNode() {
    int randCol = (int) random(cols);
    int randRow = (int) random(rows);
    return nodes[randCol][randRow];
  }

  void createGrid() { // ← FIX 2: was "createGrgetId" (typo)
    for (int i = 0; i < cols; i++)
      for (int j = 0; j < rows; j++)
        nodes[i][j] = new Node(i, j, i*grid_size+grid_size, j*grid_size+grid_size);

    for (int i = 0; i < cols; i++)
      for (int j = 0; j < rows; j++)
        addNeighbors(nodes[i][j]);
  }

  void addNeighbors(Node n) {
    for (int dx = -1; dx <= 1; dx++) {
      for (int dy = -1; dy <= 1; dy++) {
        if (dx == 0 && dy == 0) continue;
        int cc = n.col + dx;
        int cr = n.row + dy;
        if (cc >= 0 && cc < cols && cr >= 0 && cr < rows) {
          n.neighbors.add(nodes[cc][cr]); // ← FIX 3: was commented out, so no neighbors were ever added
        }
      }
    }
  }

  // FIX 4: Call this before every bfsSearch() call, otherwise visited=true
  // stays set from the previous run and BFS finds nothing on the second call
  void resetVisited() {
    for (Node[] col : nodes)
      for (Node n : col)
        n.visited = false;
  }

  void display() {
    Node n;
    for (int i = 0; i < cols; i++) {
      for (int j = 0; j < rows; j++) {
        n = nodes[i][j];
       fill(n.getColor());
        ellipse(n.position.x, n.position.y, n.w, n.h);
        //println("nodes[i][j].position.x: " + nodes[i][j].position.x);
        //println(nodes[i][j]);
      }
      //line(0, i*grid_size+grid_size, width, i*grid_size+grid_size);
    }
  }

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

  void setNodeColor(Node node, color c) {
    fill(c);
    strokeWeight(1);
    ellipse(node.position.x, node.position.y, node.w, node.h);
  }
}

