
static final int WINDOW_WIDTH = 800;
static final int WINDOW_HEIGHT = 800;
static final int ORIGINAL_FRAME_RATE = 60;

static final PVector TREE1_POSITION = new PVector(230, 600);
static final PVector TREE2_POSITION = new PVector(280, 230);
static final PVector TREE3_POSITION = new PVector(530, 520);

static final PVector TEAM0_TANK0_START_POSITION = new PVector(50, 50);
static final PVector TEAM0_TANK1_START_POSITION = new PVector(50, 150);
static final PVector TEAM0_TANK2_START_POSITION  = new PVector(50, 250);

static final PVector TEAM1_TANK0_START_POSITION = new PVector(WINDOW_WIDTH-50, WINDOW_HEIGHT-250);
static final PVector TEAM1_TANK1_START_POSITION = new PVector(WINDOW_WIDTH-50, WINDOW_HEIGHT-150);
static final PVector TEAM1_TANK2_START_POSITION = new PVector(WINDOW_WIDTH-50, WINDOW_HEIGHT-50);

static final int TANK_SIZE = 50;

static final int GRID_COLUMNS = 15;
static final int GRID_ROWS = 15;
static final int GRID_CELL_SIZE = 50;

final color team0Color = color(204, 50, 50);
final color team1Color = color(0, 150, 200);

Grid grid;

CollisionManager collisionManager;
WorldSensorImpl sensor;

Team team0;
Team team1;

Tree[] allTrees = new Tree[3];
Tank[] allTanks = new Tank[6];
ArrayList<Tank> activeTank = new ArrayList<Tank>();

int currentFrameRate = ORIGINAL_FRAME_RATE;

boolean gameOver;
boolean pause;
boolean debug;

public void settings() {
  size(WINDOW_WIDTH, WINDOW_HEIGHT);
}

void setup(){
  frameRate(ORIGINAL_FRAME_RATE);

  gameOver = false;
  pause = true;
  debug = false;

  grid = new Grid(GRID_COLUMNS, GRID_ROWS, GRID_CELL_SIZE);

  setupTrees();
  setupTeams();

  sensor = new WorldSensorImpl(grid, allTanks, team0, team1);
  setupTanks();

  collisionManager = new CollisionManager();
  addCollision();

  activateTank(allTanks[0]);
  //activateTank(allTanks[1]);
  //activateTank(allTanks[2]);
}

void setupTanks(){
  allTanks[0] = team0.tanks[0];
  allTanks[1] = team0.tanks[1];
  allTanks[2] = team0.tanks[2];
  allTanks[3] = team1.tanks[0];
  allTanks[4] = team1.tanks[1];
  allTanks[5] = team1.tanks[2];
}

void activateTank(Tank tank){
  tank.worldSensor = sensor;
  tank.cellSize = grid.grid_size;

  ArrayList<Node> baseNodes = buildBaseNodes(tank.team, NodeType.HOME_BASE);
  tank.addHomeBase(baseNodes);

  tank.tankState = TankState.SEARCH;
  tank.active = true;
  activeTank.add(tank);
}

void addCollision(){
  for (Tree t : allTrees){
    collisionManager.objects.add(t);
    grid.markObstacle(t.position, t.radius, 5);
  }

  for (Tank t : allTanks){
    collisionManager.objects.add(t);
  }
}

void setupTeams(){
  team0 = new Team(0, TANK_SIZE, team0Color, TEAM0_TANK0_START_POSITION, 1, TEAM0_TANK1_START_POSITION, 2, TEAM0_TANK2_START_POSITION, 3);
  team1 = new Team(1, TANK_SIZE, team1Color, TEAM1_TANK0_START_POSITION, 4, TEAM1_TANK1_START_POSITION, 5, TEAM1_TANK2_START_POSITION, 6);

  markBaseType(team0, NodeType.HOME_BASE);
  markBaseType(team1, NodeType.ENEMY_BASE);
}

void setupTrees(){
  allTrees[0] = new Tree((int)TREE1_POSITION.x, (int)TREE1_POSITION.y);
  allTrees[1] = new Tree((int)TREE2_POSITION.x, (int)TREE2_POSITION.y);
  allTrees[2] = new Tree((int)TREE3_POSITION.x, (int)TREE3_POSITION.y);
  //allTrees[3] = new Tree((int)350, (int)400);
  //allTrees[4] = new Tree((int)620, (int)240);
  //allTrees[5] = new Tree((int)420, (int)190);
}

void markBaseType(Team team, NodeType type) {
  int startC = floor(team.homebase_x / (float)GRID_CELL_SIZE);
  int startR = floor(team.homebase_y / (float)GRID_CELL_SIZE);
  int endC = ceil((team.homebase_x + team.homebase_width)  / (float)GRID_CELL_SIZE);
  int endR = ceil((team.homebase_y + team.homebase_height) / (float)GRID_CELL_SIZE);

  for (int c = startC; c < endC; c++){
    for (int r = startR; r < endR; r++){
      grid.markBaseType(c, r, type);
    }
  }
}

ArrayList<Node> buildBaseNodes(Team team, NodeType type) {
  ArrayList<Node> baseNodes = new ArrayList<Node>();

  int startC = floor(team.homebase_x / (float)GRID_CELL_SIZE);
  int startR = floor(team.homebase_y / (float)GRID_CELL_SIZE);
  int endC = ceil((team.homebase_x + team.homebase_width)  / (float)GRID_CELL_SIZE);
  int endR = ceil((team.homebase_y + team.homebase_height) / (float)GRID_CELL_SIZE);

  for (int c = startC; c < endC; c++) {
    for (int r = startR; r < endR; r++) {
      if (c >= 0 && c < grid.cols && r >= 0 && r < grid.rows) {
        float px = c * GRID_CELL_SIZE + GRID_CELL_SIZE;
        float py = r * GRID_CELL_SIZE + GRID_CELL_SIZE;
        Node n = new Node(c, r, px, py);
        n.type = type;
        baseNodes.add(n);
      }
    }
  }
  return baseNodes;
}

void draw(){
  background(200);

  if (!gameOver && !pause) {
    updateTanksLogic();
    updateCollision();
  }

  displayTeamBases();
  displayTanks();
  displayTrees();
  displayDebug();
  displayGUI();
}

void updateTanksLogic() {
  team0.updateLogic();
  team1.updateLogic();
}

void updateCollision(){
  collisionManager.checkForCollisions();
  collisionManager.checkBoundaryCollision();
}

void displayTeamBases() {
  team0.displayHomeBaseTeam();
  team1.displayHomeBaseTeam();
}

void displayTrees() {
  for (Tree tree : allTrees) {
    tree.display();
  }
}

void displayTanks() {
  team0.displayTanks();
  team1.displayTanks();
}

void displayGUI() {
  if (pause) {
    textSize(36);
    fill(30);
    text("Paused!\n(\'p\'-continues)\n(\'d\'-debug)\n(\'1\'/\'2\'-increase/lower fps)", width/1.7-100, height/2.5);
  }

  if (gameOver) {
    textSize(36);
    fill(30);
    text("Game Over!", width/2-100, height/2);
  }
}

void displayDebug(){
  if (debug){
    for (Tank t : activeTank){
      t.displayKnownMap();
      t.displayPath();
      t.displaySightRay();
    }

    for (Tree tree : allTrees) {
      tree.displayCollisionRadius();
    }
  }
}

void keyReleased() {
  if (key == 'p') {
    pause = !pause;
  }

  if (key == 'd') {
    debug = !debug;
  }

  if (key == '1') {
    if (currentFrameRate < ORIGINAL_FRAME_RATE * 3) {
      currentFrameRate += 10;
      frameRate(currentFrameRate);
      println("Frame rate: " + currentFrameRate);
    }
  }

  if (key == '2') {
    if (currentFrameRate > ORIGINAL_FRAME_RATE) {
      currentFrameRate -= 10;
      frameRate(currentFrameRate);
      println("Frame rate: " + currentFrameRate);
    }
  }
}
