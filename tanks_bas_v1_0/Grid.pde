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

  void createGrid() {
    for (int c = 0; c < cols; c++) {
      for (int r = 0; r < rows; r++) {
        float px = c*grid_size+grid_size;
        float py = r*grid_size+grid_size;
        nodes[c][r] = new Node(c, r, px, py);
      }
    }
    for (int c = 0; c < cols; c++) {
      for (int r = 0; r < rows; r++) {
        addNeighbors(nodes[c][r]);
      }
    }
  }

  void addNeighbors(Node n) {
    for (int dc = -1; dc <= 1; dc++) {
      for (int dr = -1; dr <= 1; dr++) {
        if (dc == 0 && dr == 0) continue;
        int nc = n.col + dc;
        int nr = n.row + dr;
        if (nc >= 0 && nc < cols && nr >= 0 && nr < rows) {
          n.neighbors.add(nodes[nc][nr]);
        }
      }
    }
  }

  Node getNode(int row, int col)
  {
    return nodes[row][col];
  }


  Node getNearestNode(PVector pvec) {
    float cx = constrain(pvec.x, 1, width - 1);
    float cy = constrain(pvec.y, 1, height - 1);

    Node  best = null;
    float bestDist = Float.MAX_VALUE;

    for (int c = 0; c < cols; c++) {
      for (int r = 0; r < rows; r++) {
        float d = dist(nodes[c][r].position.x, nodes[c][r].position.y, cx, cy);
        if (d < bestDist) {
          bestDist = d;
          best = nodes[c][r];
        }
      }
    }
    return best;
  }

  Node getNodeAt(PVector p) {
    return getNodeAt(p.x, p.y);
  }

  Node getNodeAt(float px, float py) {
    int c = (int)((px - grid_size * 0.5) / grid_size);
    int r = (int)((py - grid_size * 0.5) / grid_size);
    c = constrain(c, 0, cols - 1);
    r = constrain(r, 0, rows - 1);
    return nodes[c][r];
  }

  void display() {
    Node n;
    for (int i = 0; i < cols; i++) {
      for (int j = 0; j < rows; j++) {
        n = nodes[i][j];
        fill(n.getColor());
        ellipse(n.position.x, n.position.y, n.w, n.h);
      }
    }
  }

  NodeType senseTypeAt(int c, int r) {
    if (c < 0 || c >= cols || r < 0 || r >= rows) return NodeType.OBSTACLE;
    return nodes[c][r].type;
  }

  void markObstacle(PVector centre, float obstacleRadius, float offset) {
    float effective = obstacleRadius + offset;
    for (int c = 0; c < cols; c++)
      for (int r = 0; r < rows; r++) {
        Node n = nodes[c][r];
        if (dist(n.position.x, n.position.y, centre.x, centre.y) < effective)
          n.type = NodeType.OBSTACLE;
      }
    rebuildNeighbors();
  }

  void markBaseType(int c, int r, NodeType type) {
    if (c >= 0 && c < cols && r >= 0 && r < rows)
      nodes[c][r].type = type;
  }

  void rebuildNeighbors() {
    for (int c = 0; c < cols; c++)
      for (int r = 0; r < rows; r++)
        nodes[c][r].neighbors.clear();
    for (int c = 0; c < cols; c++)
      for (int r = 0; r < rows; r++)
        addNeighbors(nodes[c][r]);
  }
}