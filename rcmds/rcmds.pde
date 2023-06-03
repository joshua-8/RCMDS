/////////////////////////add interface elements here
BatteryGraph batteryGraph;
Joystick driveStick;
Button lTurnButton;
Button rTurnButton;
DiamondSelector armSelector;
Button armBackspaceButton;
Button armCancelButton;

//////////////////////
float batVolt=0.0;
boolean enabled=false;
////////////////////////add variables here
float Ain=0;
float Bin=0;
float Cin=0;
float Din=0;

PVector drive = new PVector(0, 0);
int autoTurns = 0;

boolean wasLeftTurnButton=false;
boolean wasRightTurnButton=false;
boolean backCancelLock=false;

void setup() {
  size(400, 1350);
  setupGamepad("Controller (XBOX 360 For Windows)");
  try {
    String[] settings=loadStrings("data/wifiSettings.txt");
    wifiIP=settings[0];
    wifiPort=int(settings[1]);
    println("wifiIP: " + wifiIP);
    println("wifiPort: " + wifiPort);
  }
  catch(Exception e) {
  }
  rcmdsSetup();
  batteryGraph=new BatteryGraph(width/3, (int)(height*.077), width*2/3, height/25, 7);
  //setup UI here
  driveStick=new Joystick(width*.2, height*.16, width*.3, 1, 1, color(0, 100, 0), color(255), "X Axis", "Y Axis", UP, LEFT, DOWN, RIGHT, 0, 0);
  lTurnButton=new Button(width*.2-30, height*.16+width*.15+50, 30, color(100, 50, 50), color(255), null, 'q', true, false, "L T");
  rTurnButton=new Button(width*.2+30, height*.16+width*.15+50, 30, color(50, 100, 50), color(255), null, 'e', true, false, "R T");
  armSelector=new DiamondSelector(width/2, (int)(height*.4), (int)(width/sqrt(2)));
  armBackspaceButton=new Button(width*.15, height*.5, 50, color(100), color(220), null, 0, true, false, "back");
  armCancelButton=new Button(width*.85, height*.5, 50, color(80, 120, 80), color(220), null, 0, true, false, "cancel");
}
void draw() {
  background(0);

  if (lTurnButton.run()||gpad.getHat("cooliehat: Hat Switch").left()) {
    lTurnButton.overrideColor=true;
    if (!wasLeftTurnButton) {
      autoTurns+=90;
    }
    wasLeftTurnButton=true;
  } else {
    wasLeftTurnButton=false;
  }
  if (rTurnButton.run()||gpad.getHat("cooliehat: Hat Switch").right()) {
    rTurnButton.overrideColor=true;
    if (!wasRightTurnButton) {
      autoTurns-=90;
    }
    wasRightTurnButton=true;
  } else {
    wasRightTurnButton=false;
  }
  if (millis()-wifiReceivedMillis>wifiRetryPingTime*disableTimeMultiplier) {
    autoTurns=0;
  }
  if (gamepadButton("Button 7", false)) {
    enabled=true;
  }
  if (gamepadButton("Button 6", false)) {
    enabled=false;
  }
  enabled=enableSwitch.run(enabled);
  /////////////////////////////////////add UI here
  drive=driveStick.run(new PVector(0, 0));
  if (armSelector.stage>=1) {
    armCancelButton.background=color(100);
    armBackspaceButton.background=color(80, 120, 80);
  } else {
    armBackspaceButton.background=color(100);
    armCancelButton.background=color(80, 120, 80);
  }
  if (armBackspaceButton.run()||(armSelector.stage>=1&&gamepadButton("Button 9", false))) {
    armBackspaceButton.overrideColor=true;
    armSelector.reset();
    backCancelLock=true;
  } else if (gamepadButton("Button 9", false)==false) {
    backCancelLock=false;
  }
  if (backCancelLock) {
    armBackspaceButton.overrideColor=true;
  }
  if (armCancelButton.run()||(!backCancelLock&&(armSelector.stage==0&&gamepadButton("Button 9", false)))) {
    armCancelButton.overrideColor=true;
    armSelector.resetOutVal();
  }
  println(armSelector.run());

  batteryGraph.run(batVolt);
  fill(255);
  textSize(30);
  text(nf(batVolt, 1, 2), width*.73, height*.08);
  textSize(20);
  text("ping: "+nf(wifiPing, 1, 0), width*.05, height*.03);

  String[] msgl={"Ain", "Bin"};
  String[] datal={str(Ain), str(Bin)};
  dispTelem(msgl, datal, width/4, height*7/8, width/2, height/4, 12);
  String[] msgr={"Cin", "Din", "auto turns"};
  String[] datar={str(Cin), str(Din), str(autoTurns)};
  dispTelem(msgr, datar, width*3/4, height*7/8, width/2, height/4, 12);

  sendWifiData(true);
  endOfDraw();
}
void WifiDataToRecv() {
  batVolt=recvFl();
  Ain=recvFl();
  Bin=recvFl();
  Cin=recvFl();
  Din=recvFl();
  ////////////////////////////////////add data to read here
}
void WifiDataToSend() {
  sendBl(enabled);
  ///////////////////////////////////add data to send here
  sendVect(drive);
  sendIn(autoTurns);
}

class DiamondSelector {
  int x;
  int y;
  int size;
  color colors[][] = {{#3692FF, #ecdb33}, {#3cdb4e, #d04242}};
  int stage;
  byte val;
  boolean wasup;
  boolean wasdown;
  boolean wasleft;
  boolean wasright;
  byte outVal;
  DiamondSelector(int _x, int _y, int _size) {
    x=_x;
    y=_y;
    size=_size;
    stage=0;
    val=(byte)unbinary("100000");
    wasup=false;
    wasdown=false;
    wasleft=false;
    wasright=false;
    outVal=32;
  }
  void reset() {
    val=(byte)unbinary("100000");
    stage=0;
  }
  void resetOutVal() {
    val=(byte)unbinary("100000");
    stage=0;
    outVal=32;
  }
  byte getVal() {
    return val;
  }
  byte getOutVal() {
    return outVal;
  }
  byte run() {
    boolean up=gamepadButton("Button 3", false);
    boolean down=gamepadButton("Button 0", false);
    boolean left=gamepadButton("Button 2", false);
    boolean right=gamepadButton("Button 1", false);
    if (stage==2) {
      if ((up&&!wasup)||(down&&!wasdown)||(left&&!wasleft)||(right&&!wasright)) {
        stage=0;
      }
    }
    if (stage==1) {
      if (up&&!wasup)
        val^=(byte)unbinary("10001");
      else if (down&&!wasdown)
        val^=(byte)unbinary("10010");
      else if (left&&!wasleft)
        val^=(byte)unbinary("10000");
      else if (right&&!wasright)
        val^=(byte)unbinary("10011");

      if (val<(byte)unbinary("10000")) {
        stage=2;
      }
    }
    if (stage==0) {
      if (up&&!wasup)
        val=(byte)unbinary("10100");
      else if (down&&!wasdown)
        val=(byte)unbinary("11000");
      else if (left&&!wasleft)
        val=(byte)unbinary("10000");
      else if (right&&!wasright)
        val=(byte)unbinary("11100");

      if (val!=(byte)unbinary("100000")) {
        stage=1;
      }
    }
    if (val<16) {
      outVal=val;
    }

    pushStyle();
    pushMatrix();
    translate(x, y);
    rotate(-PI/4);
    for (int oi=0; oi<2; oi++) { //outer row
      for (int oj=0; oj<2; oj++) { // outer col 
        for (int ii=0; ii<2; ii++) { // inner row
          for (int ij=0; ij<2; ij++) { // inner col
            color c;
            if (outVal==(oi*8+oj*4+ii*2+ij)) {
              c=255;
            } else if (stage==1&&((val>>2)&3)==oi*2+oj) {
              c=colors[ii][ij];
            } else {
              c=colors[ii][ij];
              c=mcb(c, 0.25);
            }
            noStroke();
            fill(c);
            rect((oj-.5)*size/2+(ij-.5)*size/4, (oi-.5)*size/2+(ii-.5)*size/4, size/4, size/4);
          }
        }
        color c=colors[oi][oj];
        strokeWeight(1);
        stroke(c);
        noFill();
        rect((oj-.5)*size/2, (oi-.5)*size/2, size/2, size/2);
      }
    }
    popMatrix();
    popStyle();

    wasup=up;
    wasdown=down;
    wasleft=left;
    wasright=right;

    return outVal;
  }
}

color mcb(color c, float f) {//multiply color brightness
  return color(red(c)*f, green(c)*f, blue(c)*f);
}
