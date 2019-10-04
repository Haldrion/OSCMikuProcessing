// NOTE: Need to route audio to both speakers and back to this sketch
// Used Voicemeeter to accomplish this.

import oscP5.*;// OSC
import netP5.*;

import ddf.minim.*;
import ddf.minim.analysis.*; //EQ stuff

import deadpixel.keystone.*; //mapping stuff

import processing.video.*;//video player

//Mapping vars
Keystone ks; //special obj that controls the mapping

CornerPinSurface surface; //surfaces to map the output onto
CornerPinSurface surface2;
CornerPinSurface surface3;
CornerPinSurface surface4;
CornerPinSurface surface5;
CornerPinSurface surface6;
CornerPinSurface surface7;

PGraphics eq_screen; //graphics buffers to draw to
PGraphics vid;
PGraphics terra;
PGraphics rubik;
PGraphics shape;

//Video vars
Movie myMovie;

//EQ vars
Minim minim;
AudioInput in;
FFT fft;

PImage fade;
PImage fade2;
float EQw;
int width_ = 1500;
int height_ = 950;
float rwidth_;
float rheight_;
int hVal_EQ = 0;
int sVal_EQ = 100;

//Text vars
boolean done;
int count;
int delay;

//Terrain vars
float fly_speed = 0.1;
int hVal_terr = 0;
int sVal_terr = 0;
int terr_bmp = 100;
int cols, rows;
int scl = 20;
int Tw = 2000;
int Th = 1600;
float flying = 0;
float[][] terrain;
boolean terr_vis;

//Kalidoscope/Superformula vars
boolean shape_vis;
boolean shape_hue;
int hVal_S = 0;
int sVal_S = 0;

//RUBIK VARS
int v=3;
int w=3;
int colors=6;

int l;
int m;
int n;
int sub;

float sz = 240/v;
float sze= sz*.8;

int [][][]block = new int [v][w][colors];

int millisecs;
int seconds;
int minutes;
boolean start = false;
boolean starter;
boolean rubik_vis;
boolean rubik_play;
int frame;
int s = 3;

//OSC
OscP5 oscP5;
int mouseR_X = 0;
int mouseR_Y = 0;

void setup() //-------------------------------------------------------------------------------------
{
  /* start oscP5, listening for incoming messages at port 12000 */
  oscP5 = new OscP5(this,12000);
  
  noCursor();
  shape_vis = false;
  shape_hue = false;
  //EQ calcualte waveform
  size(1500, 950, P3D);
  minim = new Minim(this);
  in = minim.getLineIn(Minim.STEREO, 512);
  fft = new FFT(in.bufferSize(), in.sampleRate());
  fft.logAverages(60,7);
  
  //mapping setup
  ks = new Keystone(this);
  surface = ks.createCornerPinSurface(800, 480, 20);
  surface2 = ks.createCornerPinSurface(1500, 950, 20);
  surface3 = ks.createCornerPinSurface(1500, 950, 20);
  surface4 = ks.createCornerPinSurface(800, 480, 20);
  surface5 = ks.createCornerPinSurface(800, 480, 20);
  surface6 = ks.createCornerPinSurface(1500, 950, 20);
  surface7 = ks.createCornerPinSurface(1500, 950, 20);
  eq_screen = createGraphics(1500, 950, P3D);
  vid = createGraphics(1500, 950, P3D);
  terra = createGraphics(1500, 950, P3D);
  rubik = createGraphics(600, 600, P3D);
  shape = createGraphics(1500, 1500, P3D);
  
  //EQ prep for draw
  eq_screen.stroke(255);
  EQw = width_*1.001/fft.avgSize();
  eq_screen.strokeWeight(w);
  eq_screen.strokeCap(SQUARE);
  
  fade = eq_screen.get(0,0,width_,height_);
  fade2 = shape.get(0,0,width_,height_);
  
  rwidth_ = width_ * 0.99;
  rheight_ = height_ * 0.99;
  
  //video prep
  hVal_EQ = 0;
  myMovie = new Movie(this, "miku.mp4");
  myMovie.loop();
  done = false;
  count=0;
  delay = 8; //8->miku.mp4 & 55->miku2
  
  //terrain prep
  cols = Tw / scl;
  rows = Th/ scl;
  terrain = new float[cols][rows];
  terr_vis = false;
  
  //RUBIKS prep
  rubik.strokeWeight(5);
  rubik.noFill();
  rubik.rectMode(CENTER);
  for(int l=0; l<v; l++){
    for(int m=0; m<w; m++){
    for(int n=0; n<colors; n++){
    block[l][m][n]=n;
    }
    }
    }
  rubik_vis = false;
  rubik_play = false;
  frame = 0;
}

//Superformula - kalidoscope
float r(float theta,float a,float b,float m,float n1,float n2,float n3)
{
  return pow(pow(abs(cos(m*theta/4.0)/a),n2) +
  pow(abs(sin(m*theta/4.0)/b),n3),-1.0/n1);
}

void draw()//-------------------------------------------------------------------------------
{
//----------------------------- VIDEO DRAW -------------------------------------
  //draw video layer
  vid.beginDraw();
  vid.background(0);
  vid.image(myMovie, 0, 0);
  if(done && count > delay) //if volume low for delay+ frames
  {                         //display thanks for watching
    vid.textSize(50);
    vid.background(0);
    vid.text("Thanks For Watching!", 150, 300); 
    vid.fill(255, 255, 255);
  }
  vid.textSize(25);
  vid.text(oscP5.ip(), 300, 35); 
  vid.fill(255, 255, 255);
  vid.endDraw();
  
//----------------------------- EQ DRAW ------------------------------------
  if(!terr_vis)
  {
  //EQ layer draw
  eq_screen.beginDraw();
  eq_screen.background(0,0,0);
  
  eq_screen.tint(255,255,255,254);//fading effect
  eq_screen.image(fade,(width_-rwidth_)/2,(height_ - rheight_)/2,rwidth_,rheight_);
  noTint();
  
  fft.forward(in.mix);//EQ
  
  eq_screen.colorMode(HSB);//color change for EQ
  eq_screen.stroke(hVal_EQ, sVal_EQ, 255);
  eq_screen.colorMode(RGB);
  
  //rainbow EQ
  for(int i = 0; i < fft.avgSize(); i++)
  {
    eq_screen.line((i*EQw)+(EQw/2), height_, (i*EQw)+(EQw/2), height_ - fft.getAvg(i)*10);
  }
  //for tunnel effect capture image
  fade = eq_screen.get(0,0,width_,height_);
  
  //draw EQ and checking whether to print txt
  eq_screen.stroke(255);
  done = true;
  for(int i = 0; i < fft.avgSize(); i++)
  {
    eq_screen.line((i*EQw)+(EQw/2), height_, (i*EQw)+(EQw/2), height_ - fft.getAvg(i)*10);
    if(fft.getAvg(i) > .1)
    {
      done = false;
    }
  }
  
  if(done) //countdown frames till display text
  {
    count++;
  }
  else
    count = 0;
    
  hVal_EQ += 2;//color change EQ
  if(hVal_EQ > 255)
  {
    hVal_EQ = 0;
  }
  
  sVal_EQ += 2;//color change EQ
  if(sVal_EQ >= 255)
  {
    sVal_EQ = 255;
  }
  
  eq_screen.endDraw();
  }
  
// ----------------------------- TERRAIN DRAW ---------------------------------
  
  if(terr_vis)
  {
  //Terrain draw
  flying -= fly_speed;

  float yoff = flying;
  for (int y = 0; y < rows; y++) {
    float xoff = 0;
    for (int x = 0; x < cols; x++) {
      terrain[x][y] = map(noise(xoff, yoff), 0, 1, -terr_bmp, terr_bmp);
      xoff += 0.2;
    }
    yoff += 0.2;
  }
  
  terra.beginDraw();
  terra.background(0);
  terra.colorMode(HSB);
  terra.stroke(hVal_terr, sVal_terr, 255);
  terra.noFill();

  terra.translate(600/2, 600/2+50);
  terra.rotateX(PI/3);
  terra.translate(-Tw/2, -Th/2);
  for (int y = 0; y < rows-1; y++) {
    terra.beginShape(TRIANGLE_STRIP);
    for (int x = 0; x < cols; x++) {
      terra.vertex(x*scl, y*scl, terrain[x][y]);
      terra.vertex(x*scl, (y+1)*scl, terrain[x][y+1]);
      //rect(x*scl, y*scl, scl, scl);
    }
    terra.endShape();
  }
  terra.endDraw();
  }
  
  
//-------------------------- KALIDOSCOPE/SUPERFORMULA -------------------------
  if(terr_vis)
  {
  //kalidiscope
  fft.forward(in.mix);
  shape.beginDraw();
  shape.background(0);
  shape.tint(255,255,255,254);
  shape.image(fade2,(width_-rwidth_)/2,(height_ - rheight_)/2,rwidth_,rheight_);
  noTint();
  
  shape.fill(0,0,0,0);
  shape.colorMode(HSB);
  shape.stroke(hVal_S, sVal_S,255);
  shape.colorMode(RGB);
  
  shape.translate(width_/2, height_/2);
  
  shape.beginShape();
  
  //add some vertices
  for(float theta = 0; theta <= 2*PI; theta += 0.05)
  {
    float rad = r(theta,
      fft.getAvg(20)*10.0/100.0, // a
      fft.getAvg(25)*10.0/100.0, // b
      15, // m
      1, // n1
      fft.getAvg(30)*10.0/100.0, // n2
      fft.getAvg(35)*10.0/100.0  // n3
    );
    float x = rad * cos(theta) * 50;
    float y =  rad * sin(theta) * 50;
    shape.vertex(x,y);
  }
  
  //println(fft.getAvg(0)*20);
    
  shape.endShape();
  
  fade2 = shape.get(0,0,width_,height_);
  shape.endDraw();
  }
  
//------------------------------------ RUBIK -----------------------------------
  if(!terr_vis && rubik_vis)
  {
  rubik.beginDraw();
  rubik.background(0,0,0);
  rubik.fill(255);
  rubik.stroke(0);
  rubik.rect(40, 15, 70, 20);
  rubik.textAlign(CENTER);
  rubik.fill(0);
  rubik.textSize(15);
  rubik.text(minutes + ":" + nf(seconds, 2)
  + "." + nf(millisecs, 1) , mouseR_X, mouseR_Y);
  //text(nf(millisecs,1),mouseR_X,mouseR_Y);
  rubik.translate(600/2,600/2);
  rubik.rotateX(-mouseR_Y*PI/300);
  rubik.rotateY(-mouseR_X*PI/300);
  //noFill();
  rubik.box(239);
  for(int l=0; l<v; l++){
  for(int m=0; m<w; m++){
  for(int n=0; n<colors; n++){
    if (n==0){ //green
      rubik.pushMatrix();
      rubik.translate(v*sz/2,0,0);
      rubik.rotateY(PI/2);
      colored(block[l][m][n]);
      rubik.rect(sz*(l-v/2.0),sz*(m-w/2.0),sze,sze);
      rubik.popMatrix();
    }
    if (n==1){ //blue
      rubik.pushMatrix();
      rubik.translate(-v*sz/2,0,0);
      rubik.rotateY(PI/2);
      colored(block[l][m][n]);
      rubik.rect(sz*(l-v/2.0),sz*(m-w/2.0),sze,sze);
      rubik.popMatrix();
    }
    if (n==2){ //white
      rubik.pushMatrix();
      rubik.translate(0,w*sz/2,0);
      rubik.rotateX(PI/2);
      colored(block[l][m][n]);
      rubik.rect(sz*(l-v/2.0),sz*(m-w/2.0),sze,sze);
      rubik.popMatrix();
    }
    if (n==3){ //yellow
      rubik.pushMatrix();
      rubik.translate(0,-w*sz/2,0);
      rubik.rotateX(PI/2);
      colored(block[l][m][n]);
      rubik.rect(sz*(l-v/2.0),sz*(m-w/2.0),sze,sze);
      rubik.popMatrix();
    }
    if (n==4){ //red
      rubik.pushMatrix();
      rubik.translate(0,0,w*sz/2);
      colored(block[l][m][n]);
      rubik.rect(sz*(l-v/2.0),sz*(m-w/2.0),sze,sze);
      rubik.popMatrix();
    }
    if (n==5){ //orange
      rubik.pushMatrix();
      rubik.translate(0,0,-w*sz/2);
      colored(block[l][m][n]);
      rubik.rect(sz*(l-v/2.0),sz*(m-w/2.0),sze,sze);
      rubik.popMatrix();
    }
  }
  }
  }
  if(start){
  if (int(millis()/100)  % 10 != millisecs){
    millisecs++;
  }
  if (millisecs >= 10){
    millisecs -= 10;
    seconds++;
  }
  if (seconds >= 60){
    seconds -= 60;
    minutes++;
  }
  }
  
  frame++;
  if(rubik_play)
  {
    if(frame % (s*12) == 0)CW0();
    if(frame % (s*12) == s)CW1();
    if(frame % (s*12) == 2*s)CW2();
    if(frame % (s*12) == 3*s)CW3();
    if(frame % (s*12) == 4*s)CW4();
    if(frame % (s*12) == 5*s)CW3();
    if(frame % (s*12) == 6*s)CW4();
    if(frame % (s*12) == 7*s)CW0();
    if(frame % (s*12) == 8*s)CW2();
    if(frame % (s*12) == 9*s)CW5();
    if(frame % (s*12) == 10*s)CW1();
    if(frame % (s*12) == 11*s)CW5();
  }
  
  rubik.endDraw();
  }
  //--------------- PROJ MAP ------------------
  
  background(0);//render the layers in 3d (proj_map)
  if (terr_vis)
  {
    surface.render(terra);
    if(shape_vis)
    {
      surface6.render(shape);
      surface7.render(shape);
    }
  }
  if (!terr_vis)
    surface2.render(eq_screen);
  if(!terr_vis)
    surface3.render(eq_screen);
  if (!terr_vis && rubik_vis)
    surface4.render(rubik);
  surface5.render(vid);
}

void mouseClicked(){
  
    if(start == false){
      starter = true;
    }
   else if(start == true){
      starter = false;
    }
  start = starter;
}void colored(int COLOR){
  if (COLOR==0){
    rubik.fill(0,100,255);
  }
  if (COLOR==1){
    rubik.fill(0,150,0);
  }
  if (COLOR==2){
    rubik.fill(200,200,0);
  }
  if (COLOR==3){
    rubik.fill(200);
  }
  if (COLOR==4){
    rubik.fill(255,0,0);
  }
  if (COLOR==5){
    rubik.fill(255,150,0);
  }
  if (COLOR==6){
    rubik.fill(150);
  }
}
void restart(){
  for(int l=0; l<v; l++){
    for(int m=0; m<w; m++){
    for(int n=0; n<colors; n++){
    block[l][m][n]=n;
    }
    }
    }
}

void movieEvent(Movie m) {
  m.read();
}

//###########################################################################
//------------------------  KEY MAPPINGS !!! ------------------------------
//##########################################################################
void oscEvent(OscMessage theOscMessage) {
  //print("### received an osc message.");
  //print(" addrpattern: "+theOscMessage.addrPattern());
  //println(" typetag: "+theOscMessage.typetag());
  
  if(theOscMessage.addrPattern().equals("/eqCS") && theOscMessage.typetag().equals("iiii")){
    hVal_EQ = theOscMessage.get(0).intValue();
    sVal_EQ = (255 - theOscMessage.get(1).intValue()) + 200;
    if (sVal_EQ > 255)
    {
      sVal_EQ = 255;
    }
    
  }
  if(theOscMessage.addrPattern().equals("/mouseRubiks") && theOscMessage.typetag().equals("iiii")){
    mouseR_X = theOscMessage.get(2).intValue();
    mouseR_Y = theOscMessage.get(3).intValue();
  }
  if(theOscMessage.addrPattern().equals("/terrainSB") && theOscMessage.typetag().equals("iiii")){
    fly_speed = theOscMessage.get(0).intValue()/255.0;
    terr_bmp = 260 - (theOscMessage.get(1).intValue());
  }
  if(theOscMessage.addrPattern().equals("/terrainCS") && theOscMessage.typetag().equals("iiii")){
    hVal_terr = theOscMessage.get(0).intValue();
    sVal_terr = theOscMessage.get(1).intValue();
  }
  if(theOscMessage.addrPattern().equals("/shapeCS") && theOscMessage.typetag().equals("iiii")){
    hVal_S = theOscMessage.get(0).intValue();
    sVal_S = theOscMessage.get(1).intValue();
  }
  
  else if(theOscMessage.addrPattern().equals("/key") && theOscMessage.typetag().equals("c")){
   //print(theOscMessage.get(0).charValue());
    switch(theOscMessage.get(0).charValue()) {
    case 'C':
      // enter/leave calibration mode, where surfaces can be warped 
      // and moved
      ks.toggleCalibration();
      break;
  
    case 'l':
      // loads the saved layout
      ks.load();
      break;
  
    case 'S':
      // saves the layout
      ks.save();
      break;
      
     case 's':
      shape_vis = !shape_vis;
      if(shape_vis)
        shape_hue = false;
      break;
      
     case 'a':
      shape_hue = !shape_hue;
      break;
      
    case 't':
      // toggle terrain
      terr_vis = !terr_vis;
      rubik_vis = false;
      if(terr_vis)
      {
        shape_vis = false;
        shape_hue = false;
      }
      break;
      
     case 'o':
      // toggle terrain
      terr_vis = !terr_vis;
      rubik_vis = false;
      if(terr_vis)
      {
        shape_vis = true;
      }
      break;
      
    case 'y':
      // toggle terrain
      terr_vis = !terr_vis;
      rubik_vis = true;
      rubik_play  = false;
      restart();
      break;
    
    /********** RUBIK'S ****************/
    case 'c':
      rubik_vis = !rubik_vis;
      break;
    
    case'p':
      rubik_play = !rubik_play;
      break;
    
    case'n':
      rubik_play = false;
      restart();
      break;
      
    case ' ':
      millisecs = 0;
      seconds = 0;
      minutes = 0;
      break;
    }
  }
}

void mouseMoved(){
  mouseR_X = mouseX;
  mouseR_Y = mouseY;
}

void keyPressed() {
  switch(key) {
  case 'C':
    // enter/leave calibration mode, where surfaces can be warped 
    // and moved
    ks.toggleCalibration();
    break;

  case 'l':
    // loads the saved layout
    ks.load();
    break;

  case 'S':
    // saves the layout
    ks.save();
    break;
    
   case 's':
    shape_vis = !shape_vis;
    if(shape_vis)
      shape_hue = false;
    break;
    
   case 'a':
    shape_hue = !shape_hue;
    break;
    
  case 't':
    // toggle terrain
    terr_vis = !terr_vis;
    rubik_vis = false;
    if(terr_vis)
    {
      shape_vis = false;
      shape_hue = false;
    }
    break;
    
   case 'o':
    // toggle terrain
    terr_vis = !terr_vis;
    rubik_vis = false;
    if(terr_vis)
    {
      shape_vis = true;
    }
    break;
    
  case 'y':
    // toggle terrain
    terr_vis = !terr_vis;
    rubik_vis = true;
    rubik_play  = false;
    restart();
    break;
  }
  /********** RUBIK'S ****************/
  if(key == 'c'){
    rubik_vis = !rubik_vis;
  }
  
  if(key == 'p'){
    rubik_play = !rubik_play;
  }
  
  if(key == 'n'){
    rubik_play = false;
    restart();
  }
  if(key == ' '){
    millisecs = 0;
    seconds = 0;
    minutes = 0;
  }
  /**************************/
  if(key == 'r'){
    CW1();
  }
  if(key == 'R'){
    CCW1();
  }
  if(key == 'L'){
    CCW0();
  }
  /**************************/
  if(key == 'u'){
    CW2();
  }
  if(key == 'U'){
    CCW2();
  }
  if(key == 'd'){
    CW3();
  }
  if(key == 'D'){
    CCW3();
  }
  /**************************/
  if(key == 'f'){
    CW4();
  }
  if(key == 'F'){
    CCW4();
  }
  if(key == 'b'){
    CW5();
  }
  if(key == 'B'){
    CCW5();
  }
  /**************************/
  if(key == 'x'){
    CW1();
    CCW0();
    if(v>2){
      M1CW();
    }
  }
  if(key == 'X'){
    CCW1();
    CW0();
    if(v>2){
      M1CCW();
    }
  }
  if(key == 'y'){
    CW2();
    CCW3();
    if(v>2){
      E1CW();
    }
  }
  if(key == 'Y'){
    CCW2();
    CW3();
    if(v>2){
      E1CCW();
    }
  }
  if(key == 'z'){
    CW4();
    CCW5();
    if(v>2){
      S1CW();
    }
  }
  if(key == 'Z'){
    CCW4();
    CW5();
    if(v>2){
      S1CCW();
    }
  }
  /**************************/
  if(v>2){
    if(key == 'm'){
      M1CW();
    }
    if(key == 'M'){
      M1CCW();
    }
    if(key == 'e'){
      E1CW();
    }
    if(key == 'E'){
      E1CCW();
    }
    if(key == 's'){
      S1CW();
    }
    if(key == 'S'){
      S1CCW();
    }
  }
}

//---------------- TONS OF RUBIK CUBE CODE (FROM ONLINE) ----------------------
void CW1(){//R
  for(int count=0; count<(w); count++){
    sub =                    block[0][count]    [2];
    block[0][count]    [2] = block[0][w-1-count][4];
    block[0][w-1-count][4] = block[0][w-1-count][3];
    block[0][w-1-count][3] = block[0][count]    [5];
    block[0][count]    [5] = sub;
  }
  //corners
  for(int ecount=0; ecount<w-1; ecount++){
    sub                              = block[v-1]       [ecount]    [1];
    block[v-1]       [ecount]    [1] = block[v-1-ecount][w-1]       [1];
    block[v-1-ecount][w-1]       [1] = block[0]         [w-1-ecount][1];
    block[0]         [w-1-ecount][1] = block[ecount]    [0]         [1];
    block[ecount]    [0]         [1] = sub;
  }
}
void CCW0(){//L'
  for(int count=0; count<(w); count++){
    sub =                      block[v-1][count]    [2];
    block[v-1][count]    [2] = block[v-1][w-1-count][4];
    block[v-1][w-1-count][4] = block[v-1][w-1-count][3];
    block[v-1][w-1-count][3] = block[v-1][count]    [5];
    block[v-1][count]    [5] = sub;
  }
  //corners
  for(int ecount=0; ecount<w-1; ecount++){
    sub                              = block[v-1]       [ecount]    [0];
    block[v-1]       [ecount]    [0] = block[v-1-ecount][w-1]       [0];
    block[v-1-ecount][w-1]       [0] = block[0]         [w-1-ecount][0];
    block[0]         [w-1-ecount][0] = block[ecount]    [0]         [0];
    block[ecount]    [0]         [0] = sub;
  }
}
void CCW1(){//R'
  for(int count=0; count<(w); count++){
    sub                    = block[0][count]    [5];
    block[0][count]    [5] = block[0][w-1-count][3];
    block[0][w-1-count][3] = block[0][w-1-count][4];
    block[0][w-1-count][4] = block[0][count]    [2];
    block[0][count]    [2] = sub;
  }
  //corners
  for(int ecount=0; ecount<w-1; ecount++){
    sub                              = block[ecount]    [0]         [1];
    block[ecount]    [0]         [1] = block[0]         [w-1-ecount][1];
    block[0]         [w-1-ecount][1] = block[v-1-ecount][w-1]       [1];
    block[v-1-ecount][w-1]       [1] = block[v-1]       [ecount]    [1];
    block[v-1]       [ecount]    [1] = sub;
  }
}
void CW0(){//L
  for(int count=0; count<(w); count++){
    sub                      = block[v-1][count]    [5];
    block[v-1][count]    [5] = block[v-1][w-1-count][3];
    block[v-1][w-1-count][3] = block[v-1][w-1-count][4];
    block[v-1][w-1-count][4] = block[v-1][count]    [2];
    block[v-1][count]    [2] = sub;
  }
  //corners
  for(int ecount=0; ecount<w-1; ecount++){
    sub                              = block[ecount]    [0]         [0];
    block[ecount]    [0]         [0] = block[0]         [w-1-ecount][0];
    block[0]         [w-1-ecount][0] = block[v-1-ecount][w-1]       [0];
    block[v-1-ecount][w-1]       [0] = block[v-1]       [ecount]    [0];
    block[v-1]       [ecount]    [0] = sub;
  }
}
/*8*8*8*8*8*8*8*   *8*8*8*8*8*8*8*   *8*8*8*8*8*8*8*/
void CW2(){//U
  for(int count=0; count<(v); count++){
    sub                      = block[count]    [w-1][0];
    block[count]    [w-1][0] = block[count]    [w-1][4];
    block[count]    [w-1][4] = block[v-1-count][w-1][1];
    block[v-1-count][w-1][1] = block[v-1-count][w-1][5];
    block[v-1-count][w-1][5] = sub;
  }
  //corners
  for(int ecount=0; ecount<w-1; ecount++){
    sub                              = block[0]         [ecount]    [2];
    block[0]         [ecount]    [2] = block[v-1-ecount][0]         [2];
    block[v-1-ecount][0]         [2] = block[v-1]       [w-1-ecount][2];
    block[v-1]       [w-1-ecount][2] = block[ecount]    [w-1]       [2];
    block[ecount]    [w-1]       [2] = sub;
  }
}
void CCW3(){//D'
  for(int count=0; count<(v); count++){
    sub                    = block[count]    [0][0];
    block[count]    [0][0] = block[count]    [0][4];
    block[count]    [0][4] = block[v-1-count][0][1];
    block[v-1-count][0][1] = block[v-1-count][0][5];
    block[v-1-count][0][5] = sub;
  }
  //corners
  for(int ecount=0; ecount<w-1; ecount++){
    sub                              = block[0]         [ecount]    [3];
    block[0]         [ecount]    [3] = block[v-1-ecount][0]         [3];
    block[v-1-ecount][0]         [3] = block[v-1]       [w-1-ecount][3];
    block[v-1]       [w-1-ecount][3] = block[ecount]    [w-1]       [3];
    block[ecount]    [w-1]       [3] = sub;
  }
}
void CCW2(){//U'
  for(int count=0; count<(v); count++){
    sub                      = block[v-1-count][w-1][5];
    block[v-1-count][w-1][5] = block[v-1-count][w-1][1];
    block[v-1-count][w-1][1] = block[count]    [w-1][4];
    block[count]    [w-1][4] = block[count]    [w-1][0];
    block[count]    [w-1][0] = sub;
  }
  //corners
  for(int ecount=0; ecount<w-1; ecount++){
    sub                              = block[ecount]    [w-1]       [2];
    block[ecount]    [w-1]       [2] = block[v-1]       [w-1-ecount][2];
    block[v-1]       [w-1-ecount][2] = block[v-1-ecount][0]         [2];
    block[v-1-ecount][0]         [2] = block[0]         [ecount]    [2];
    block[0]         [ecount]    [2] = sub;
  }
}
void CW3(){//D
  for(int count=0; count<(v); count++){
    sub                    = block[v-1-count][0][5];
    block[v-1-count][0][5] = block[v-1-count][0][1];
    block[v-1-count][0][1] = block[count]    [0][4];
    block[count]    [0][4] = block[count]    [0][0];
    block[count]    [0][0] = sub;
  }
  //corners
  for(int ecount=0; ecount<w-1; ecount++){
    sub                              = block[ecount]    [w-1]       [3];
    block[ecount]    [w-1]       [3] = block[v-1]       [w-1-ecount][3];
    block[v-1]       [w-1-ecount][3] = block[v-1-ecount][0]         [3];
    block[v-1-ecount][0]         [3] = block[0]         [ecount]    [3];
    block[0]         [ecount]    [3] = sub;
  }
}
/*8*8*8*8*8*8*8*   *8*8*8*8*8*8*8*   *8*8*8*8*8*8*8*/
void CW4(){//F
  for(int count=0; count<(v); count++){
    sub                            = block[0]        [count]    [0];
    block[0]        [count]    [0] = block[count]    [w-1]      [3];
    block[count]    [w-1]      [3] = block[0]        [w-1-count][1];
    block[0]        [w-1-count][1] = block[v-1-count][w-1]      [2];
    block[v-1-count][w-1]      [2] = sub;
  }
  //corners
  for(int ecount=0; ecount<w-1; ecount++){
    sub                              = block[0]         [ecount]    [4];
    block[0]         [ecount]    [4] = block[ecount]    [w-1]       [4];
    block[ecount]    [w-1]       [4] = block[v-1]       [w-1-ecount][4];
    block[v-1]       [w-1-ecount][4] = block[v-1-ecount][0]         [4];
    block[v-1-ecount][0]         [4] = sub;
  }
}
void CCW5(){//B'
  for(int count=0; count<(v); count++){
    sub                            = block[v-1]      [count]    [0];
    block[v-1]      [count]    [0] = block[count]    [0]        [3];
    block[count]    [0]        [3] = block[v-1]      [w-1-count][1];
    block[v-1]      [w-1-count][1] = block[v-1-count][0]        [2];
    block[v-1-count][0]        [2] = sub;
  }
  //corners
  for(int ecount=0; ecount<w-1; ecount++){
    sub                              = block[0]         [ecount]    [5];
    block[0]         [ecount]    [5] = block[ecount]    [w-1]       [5];
    block[ecount]    [w-1]       [5] = block[v-1]       [w-1-ecount][5];
    block[v-1]       [w-1-ecount][5] = block[v-1-ecount][0]         [5];
    block[v-1-ecount][0]         [5] = sub;
  }
}
void CCW4(){//F'
  for(int count=0; count<(v); count++){
    sub                            = block[v-1-count][w-1]      [2];
    block[v-1-count][w-1]      [2] = block[0]        [w-1-count][1];
    block[0]        [w-1-count][1] = block[count]    [w-1]      [3];
    block[count]    [w-1]      [3] = block[0]        [count]    [0];
    block[0]        [count]    [0] = sub;
  }
  //corners
  for(int ecount=0; ecount<w-1; ecount++){
    sub                              = block[v-1-ecount][0]         [4];
    block[v-1-ecount][0]         [4] = block[v-1]       [w-1-ecount][4];
    block[v-1]       [w-1-ecount][4] = block[ecount]    [w-1]       [4];
    block[ecount]    [w-1]       [4] = block[0]         [ecount]    [4];
    block[0]         [ecount]    [4] = sub;
  }
}
void CW5(){//B
  for(int count=0; count<(v); count++){
    sub                            = block[v-1-count][0]        [2];
    block[v-1-count][0]        [2] = block[v-1]      [w-1-count][1];
    block[v-1]      [w-1-count][1] = block[count]    [0]        [3];
    block[count]    [0]        [3] = block[v-1]      [count]    [0];
    block[v-1]      [count]    [0] = sub;
  }
  //corners
  for(int ecount=0; ecount<w-1; ecount++){
    sub                              = block[v-1-ecount][0]         [5];
    block[v-1-ecount][0]         [5] = block[v-1]       [w-1-ecount][5];
    block[v-1]       [w-1-ecount][5] = block[ecount]    [w-1]       [5];
    block[ecount]    [w-1]       [5] = block[0]         [ecount]    [5];
    block[0]         [ecount]    [5] = sub;
  }

}

 void M1CW(){
    for(int count=0; count<(w); count++){
      sub =                    block[1][count]    [2];
      block[1][count]    [2] = block[1][w-1-count][4];
      block[1][w-1-count][4] = block[1][w-1-count][3];
      block[1][w-1-count][3] = block[1][count]    [5];
      block[1][count]    [5] = sub;
    }
  }
  void M1CCW(){
    for(int count=0; count<(w); count++){
      sub                    = block[0][count]    [5];
      block[0][count]    [5] = block[0][w-1-count][3];
      block[0][w-1-count][3] = block[0][w-1-count][4];
      block[0][w-1-count][4] = block[0][count]    [2];
      block[0][count]    [2] = sub;
    }
  }
  void E1CW(){
    for(int count=0; count<(v); count++){
      sub                      = block[count]    [w-2][0];
      block[count]    [w-2][0] = block[count]    [w-2][4];
      block[count]    [w-2][4] = block[v-1-count][w-2][1];
      block[v-1-count][w-2][1] = block[v-1-count][w-2][5];
      block[v-1-count][w-2][5] = sub;
    }
  }
  void E1CCW(){
    for(int count=0; count<(v); count++){
      sub                      = block[v-1-count][w-2][5];
      block[v-1-count][w-2][5] = block[v-1-count][w-2][1];
      block[v-1-count][w-2][1] = block[count]    [w-2][4];
      block[count]    [w-2][4] = block[count]    [w-2][0];
      block[count]    [w-2][0] = sub;
    }
  }
  void S1CW(){
    for(int count=0; count<(v); count++){
      sub                            = block[1]        [count]    [0];
      block[1]        [count]    [0] = block[count]    [w-2]      [3];
      block[count]    [w-2]      [3] = block[1]        [w-1-count][1];
      block[1]        [w-1-count][1] = block[v-1-count][w-2]      [2];
      block[v-1-count][w-2]      [2] = sub;
    }
  }
  void S1CCW(){
    for(int count=0; count<(v); count++){
      sub                            = block[v-1-count][w-2]      [2];
      block[v-1-count][w-2]      [2] = block[1]        [w-1-count][1];
      block[1]        [w-1-count][1] = block[count]    [w-2]      [3];
      block[count]    [w-2]      [3] = block[1]        [count]    [0];
      block[1]        [count]    [0] = sub;
    }
  }
