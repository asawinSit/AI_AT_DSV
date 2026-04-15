// Följande kan användas som bas inför uppgiften.
// Syftet är att sammanställa alla varabelvärden i scenariet.
// Variabelnamn har satts för att försöka överensstämma med exempelkoden.
// Klassen Tank är minimal och skickas mer med som koncept(anrop/states/vektorer).

boolean left, right, up, down;
boolean mouse_pressed;

PImage tree_img;
PVector tree1_pos, tree2_pos, tree3_pos;

Tree[] allTrees   = new Tree[3];

// Team0
color team0Color;
PVector team0_tank0_startpos;
PVector team0_tank1_startpos;
PVector team0_tank2_startpos;

// Team1
color team1Color;
PVector team1_tank0_startpos;
PVector team1_tank1_startpos;
PVector team1_tank2_startpos;

int tank_size;

boolean gameOver;
boolean pause;
boolean debug;

Grid grid;
int cols = 15;
int rows = 15;
int grid_size = 50;

Team team0;
Team team1;


//for debug
Tank selectedTank;

Tank[] allTanks = new Tank[6];

//======================================
void setup()
{
  size(800, 800);
  up             = false;
  down           = false;
  mouse_pressed  = false;

  gameOver       = false;
  pause          = true;
  debug = false;

  // Trad

  tree1_pos = new PVector(230, 600);
  tree2_pos = new PVector(280, 230);
  tree3_pos = new PVector(530, 520);

    allTrees[0] = new Tree((int)tree1_pos.x, (int)tree1_pos.y);
    allTrees[1] = new Tree((int)tree2_pos.x, (int)tree2_pos.y);
    allTrees[2] = new Tree((int)tree3_pos.x, (int)tree3_pos.y);

  tank_size = 50;

  // Team0


  team0Color  = color(204, 50, 50);             // Base Team 0(red)
  team0_tank0_startpos  = new PVector(50, 50);
  team0_tank1_startpos  = new PVector(50, 150);
  team0_tank2_startpos  = new PVector(50, 250);

  team0 = new Team(0, tank_size, team0Color, team0_tank0_startpos, 1, team0_tank1_startpos, 2, team0_tank2_startpos, 3);


  team1Color  = color(0, 150, 200);
  team1_tank0_startpos  = new PVector(width-50, height-250);
  team1_tank1_startpos  = new PVector(width-50, height-150);
  team1_tank2_startpos  = new PVector(width-50, height-50);

  // Team1
  team1 = new Team(1, tank_size, team1Color, team1_tank0_startpos, 4, team1_tank1_startpos, 5, team1_tank2_startpos, 6);
  // Base Team 1(blue)
  //tank0_startpos = new PVector(50, 50);

  allTanks[0] = team0.tanks[0];
  allTanks[1] = team0.tanks[1];
  allTanks[2] = team0.tanks[2];
  allTanks[3] = team1.tanks[0];
  allTanks[4] = team1.tanks[1];
  allTanks[5] = team1.tanks[2];

  selectedTank = allTanks[0]; // Start with the first tank selected
  selectedTank.state = 0; // Set initial state to "move"

  grid = new Grid(cols, rows, grid_size);
  setBaseNodesForTeam(team0, true);
  setBaseNodesForTeam(team1, false);
}

void setBaseNodesForTeam(Team team, boolean isHomeBase) {
  // 1. Calculate how many nodes wide/high the base is
  int baseCols = ceil(team.homebase_width / (float)grid_size);
  int baseRows = ceil(team.homebase_height / (float)grid_size);
  
  Node[][] baseNodes = new Node[baseCols][baseRows];

  // 2. Find the starting index in the GLOBAL grid
  int startIdxX = floor(team.homebase_x / (float)grid_size);
  int startIdxY = floor(team.homebase_y / (float)grid_size);

  // 3. Only loop through the required area
  for (int i = 0; i < baseCols; i++) {
    for (int j = 0; j < baseRows; j++) {
      int globalX = startIdxX + i;
      int globalY = startIdxY + j;

      // Ensure we don't go out of the global grid bounds
      if (globalX >= 0 && globalX < cols && globalY >= 0 && globalY < rows) {
        Node n = grid.nodes[globalX][globalY];
        baseNodes[i][j] = n;
        
        n.type = isHomeBase ? NodeType.HOME_BASE : NodeType.ENEMY_BASE;
      }
    }
  }
  team.setBaseNodes(baseNodes);
}
void draw()
{
  background(200);
  //checkForInput(); // Kontrollera inmatning.

  if (!gameOver && !pause) {

    // UPDATE LOGIC
    updateTanksLogic();

    // CHECK FOR COLLISIONS
    //checkForCollisions();
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
    grid.display();

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
  System.out.println("keyPressed!");

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
  System.out.println("keyReleased!");
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
    selectedTank.state = 0; // Move state
  }
  if (key == '1') {
    selectedTank.state = 1; // Move state
  }

  if (key == '2') {
    selectedTank.state = 2; // reverse state
  }
}
