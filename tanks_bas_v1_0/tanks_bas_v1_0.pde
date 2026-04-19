// Följande kan användas som bas inför uppgiften.
// Syftet är att sammanställa alla varabelvärden i scenariet.
// Variabelnamn har satts för att försöka överensstämma med exempelkoden.
// Klassen Tank är minimal och skickas mer med som koncept(anrop/states/vektorer).

boolean left, right, up, down;
boolean mouse_pressed;

int width = 800;
int height = 800;

public final PVector tree1_pos = new PVector(230, 600);
public final PVector tree2_pos = new PVector(280, 230);
public final PVector tree3_pos = new PVector(530, 520);
Tree[] allTrees   = new Tree[3];

// Team0
public final color team0Color = color(204, 50, 50);
public final PVector team0_tank0_startpos = new PVector(50, 50);
public final PVector team0_tank1_startpos = new PVector(50, 150);
public final PVector team0_tank2_startpos  = new PVector(50, 250);

// Team1
public final color team1Color = color(0, 150, 200);
public final PVector team1_tank0_startpos = new PVector(width-50, height-250);
public final PVector team1_tank1_startpos = new PVector(width-50, height-150);
public final PVector team1_tank2_startpos = new PVector(width-50, height-50);

public final int tank_size  = 50;

boolean gameOver;
boolean pause;
boolean debug;

Grid grid;
int cols = 15;
int rows = 15;
int grid_size = 50;

Team team0;
Team team1;

CollisionManager collisionManager;
//for debug
Tank selectedTank;

Tank[] allTanks = new Tank[6];

WorldSensorImpl sensor;

static final int ORIGINAL_FRAME_RATE = 60;
int currentFrameRate = ORIGINAL_FRAME_RATE;

public void settings() {
  size(width, height);
}

void setup()
{

  frameRate(ORIGINAL_FRAME_RATE);
  up             = false;
  down           = false;
  mouse_pressed  = false;

  gameOver       = false;
  pause          = true;
  debug = false;

  grid = new Grid(cols, rows, grid_size);

  setupTrees();
  setupTeams();
  setupTanks();

  collisionManager = new CollisionManager();

  for (Tree t : allTrees)
  {
    collisionManager.objects.add(t);
    grid.markObstacle(t.position, t.radius, 5);
  }

  for (Tank t : allTanks)
  {
    collisionManager.objects.add(t);
  }

  selectedTank = allTanks[0];
  allTanks[0].tankState = TankState.SEARCH;
  allTanks[0].active = true;
}

void setupTanks()
{
  allTanks[0] = team0.tanks[0];
  allTanks[1] = team0.tanks[1];
  allTanks[2] = team0.tanks[2];
  allTanks[3] = team1.tanks[0];
  allTanks[4] = team1.tanks[1];
  allTanks[5] = team1.tanks[2];

  sensor = new WorldSensorImpl(grid, allTanks, team0, team1);
  allTanks[0].worldSensor = sensor;
  allTanks[0].cellSize = grid.grid_size;

  ArrayList<Node> homeNodes = buildBaseNodes(team0, NodeType.HOME_BASE);
  allTanks[0].addHomeBase(homeNodes);
}

void setupTeams()
{
  team0 = new Team(0, tank_size, team0Color, team0_tank0_startpos, 1, team0_tank1_startpos, 2, team0_tank2_startpos, 3);
  team1 = new Team(1, tank_size, team1Color, team1_tank0_startpos, 4, team1_tank1_startpos, 5, team1_tank2_startpos, 6);

  markBaseType(team0, NodeType.HOME_BASE);
  markBaseType(team1, NodeType.ENEMY_BASE);
}

void setupTrees()
{
  allTrees[0] = new Tree((int)tree1_pos.x, (int)tree1_pos.y);
  allTrees[1] = new Tree((int)tree2_pos.x, (int)tree2_pos.y);
  allTrees[2] = new Tree((int)tree3_pos.x, (int)tree3_pos.y);
  //allTrees[3] = new Tree((int)350, (int)400);
  //allTrees[4] = new Tree((int)620, (int)240);
  //allTrees[5] = new Tree((int)420, (int)190);
}

void markBaseType(Team team, NodeType type) {
  int startC = floor(team.homebase_x / (float)grid_size);
  int startR = floor(team.homebase_y / (float)grid_size);
  int endC   = ceil((team.homebase_x + team.homebase_width)  / (float)grid_size);
  int endR   = ceil((team.homebase_y + team.homebase_height) / (float)grid_size);

  for (int c = startC; c < endC; c++)
    for (int r = startR; r < endR; r++)
      grid.markBaseType(c, r, type);
}

ArrayList<Node> buildBaseNodes(Team team, NodeType type) {
  ArrayList<Node> result = new ArrayList<Node>();

  int startC = floor(team.homebase_x / (float)grid_size);
  int startR = floor(team.homebase_y / (float)grid_size);
  int endC   = ceil((team.homebase_x + team.homebase_width)  / (float)grid_size);
  int endR   = ceil((team.homebase_y + team.homebase_height) / (float)grid_size);

  for (int c = startC; c < endC; c++) {
    for (int r = startR; r < endR; r++) {
      if (c >= 0 && c < grid.cols && r >= 0 && r < grid.rows) {
        float px = c * grid_size + grid_size;
        float py = r * grid_size + grid_size;
        Node n   = new Node(c, r, px, py);
        n.type   = type;
        result.add(n);
      }
    }
  }
  return result;
}

void draw()
{
  background(200);
  //checkForInput(); // Kontrollera inmatning.

  if (!gameOver && !pause) {

    // UPDATE LOGIC
    updateTanksLogic();

    collisionManager.checkForCollisions();
  }

  // UPDATE DISPLAY
  displayHomeBase();
  displayTanks();
  displayTrees();
  displayDebug();
  displayGUI();
}

//======================================

//======================================
// Följande bör ligga i klassen Team
void displayHomeBase() {
  team0.displayHomeBaseTeam();
  team1.displayHomeBaseTeam();
}

// Följande bör ligga i klassen Tree
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
    text("...Paused! (\'p\'-continues)\n(upp/ner-change velocity)", width/1.7-100, height/2.5);
  }

  if (gameOver) {
    textSize(36);
    fill(30);
    text("Game Over!", width/2-100, height/2);
  }
}

void displayDebug()
{
  if (debug)
  {
    // grid.display();

    for (Node n : allTanks[0].knownMap.values()) {
      fill(n.getColor());
      ellipse(n.position.x, n.position.y, n.w, n.h);
    }

    allTanks[0].displaySightRay();
    allTanks[0].displayPath();
    //for (Tank tank : allTanks){
    //  tank.displaySightRay();
    //}

    for (Tree tree : allTrees) {
      tree.displayCollisionRadius();
    }
  }
}

//======================================
void updateTanksLogic() {
  team0.updateLogic();
  team1.updateLogic();
}

//======================================
void keyPressed() {
  //System.out.println("keyPressed!");

  if (key == CODED) {
    switch(keyCode) {
    case LEFT:
      left = true;
      break;
    case RIGHT:
      right = true;
      break;
    case UP:
      up = true;
      break;
    case DOWN:
      down = true;
      break;
    }
  }
}

void keyReleased() {
  //System.out.println("keyReleased!");
  if (key == CODED) {
    switch(keyCode) {
    case LEFT:
      left = false;
      break;
    case RIGHT:
      right = false;
      break;
    case UP:
      up = false;

      break;
    case DOWN:
      down = false;

      break;
    }
  }

  if (key == 'p') {
    pause = !pause;
  }

  if (key == 'g') {
    debug = !debug;
  }

  if (selectedTank == null) return; // Om ingen tank är vald, gör inget.

  if (key == '0') {

    selectedTank.targetNode =  grid.getRandomNode();
    println( selectedTank.targetNode.row + " " + selectedTank.targetNode.col);
    selectedTank.tankState = TankState.SEARCH;
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
