import netP5.*;
import oscP5.*;

//###########################################

String IP = "127.0.0.1"; //REPLACE W/ CLIENT IP

//###########################################

OscP5 oscP5;
NetAddress myRemoteLocation;

String txt = "EQ color & saturation";
String ctrl = "/eqCS";
boolean overIP = false;
boolean editIP = false;

void setup() {
  size(765,765);
  frameRate(25);
  /* start oscP5, listening for incoming messages at port 12000 */
  oscP5 = new OscP5(this,8000);
  
  /* myRemoteLocation is a NetAddress. a NetAddress takes 2 parameters,
   * an ip address and a port number. myRemoteLocation is used as parameter in
   * oscP5.send() when sending osc packets to another computer, device, 
   * application. usage see below. for testing purposes the listening port
   * and the port of the remote location address are the same, hence you will
   * send messages back to this sketch.
   */
  myRemoteLocation = new NetAddress(IP, 12000);
}


void draw() {
  background(0);
  textSize(36);
  textAlign(CENTER);
  text("Mouse controls " + txt, width/2, height/2);
  noFill();
  if(editIP)
  {
    stroke(204, 102, 0);
  }
  else
  {
    stroke(153);
  }
  rect(0, 0, 500, 30);
  textSize(20);
  text(IP, 500/2, 30/2);
}

void mouseMoved()
{
  //check if mouse is over rectangle
  if (mouseX < 500 && mouseY < 30)
  {
    overIP = true;
  }
  else
  {
    overIP = false;
    editIP = false;
  }
  
  if(!editIP)
  {
    OscMessage mouseMessage = new OscMessage(ctrl);
    
    mouseMessage.add((int)(mouseX/3.0)); /* add an int to the osc message */
    mouseMessage.add((int)(mouseY/3.0)); /* add an int to the osc message */
    mouseMessage.add(mouseX); /* add an int to the osc message */
    mouseMessage.add(mouseY); /* add an int to the osc message */
  
    /* send the message */
    myRemoteLocation = new NetAddress(IP, 12000);
    oscP5.send(mouseMessage, myRemoteLocation);
  }
}
void mousePressed()
{
  if(overIP)
  {
    editIP = true;
    IP = "";
  }
}

void keyPressed()
{
  if(editIP)
  {
    IP += key;
  }
  
  else
  {
    if(key == 'y' || key == 'c')
    {
      txt = "rubik's cube's rotation";
      ctrl = "/mouseRubiks";
    }
    else if (key == 't')
    {
      txt = "terrain speed & bump";
      ctrl = "/terrainSB";
    }
    else if (key == 's')
    {
      txt = "shape color & saturation";
      ctrl = "/shapeCS";
    }
    
    if(Character.isDigit(key))
    {
      switch(key)
      {
        case('1'):
          txt = "EQ color & saturation";
          ctrl = "/eqCS";
          break;
        case('2'):
          txt = "rubik's cube's rotation";
          ctrl = "/mouseRubiks";
          break;
        case('3'):
          txt = "terrain speed & bump";
          ctrl = "/terrainSB";
          break;
        case('4'):
          txt = "terrain color & saturation";
          ctrl = "/terrainCS";
          break;
        case('5'):
          txt = "shape color & saturation";
          ctrl = "/shapeCS";
          break;
      }
    }
  }
  
  OscMessage keyMessage = new OscMessage("/key");
  
  /* add the char of the key pressed to the osc message */
  keyMessage.add(key);
  
  /* send the message */
  oscP5.send(keyMessage, myRemoteLocation);
}
