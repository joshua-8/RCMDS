float upperArmLength=0.1016;
float forearmLength=0.1524;
float handLength=0.05;
ArmConfigStruct armConfig = new ArmConfigStruct(upperArmLength, forearmLength);
/////////////////////////add interface elements here
BatteryGraph batteryGraph;
Joystick driveStick;
Button lTurnButton;
Button rTurnButton;
DiamondSelector armSelector;
Button armBackspaceButton;
Button armCancelButton;
Joystick armStick;
Slider wristSlider;
Slider middleSlider;
Slider rightSlider;
Button grabButton;
Button dropButton;
RobotDraw robotCtrlDraw;

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
PVector armJog = new PVector(0, 0);
float wristAngleSliderVal=0;
float middleAngle=0;
float rightAngle=0;

float armXOut=0;
float armYOut=0;
float armWristOut=0;

boolean wasLeftTurnButton=false;
boolean wasRightTurnButton=false;
boolean backCancelLock=false;

int grabState=0;

PGraphics robotCanvas;

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
  driveStick=new Joystick(width*.2, height*.16, width*.3, 1, 1, color(0, 100, 0), color(255), "X Axis", "Y Axis", 'w', 'a', 's', 'd', 0, 0);
  lTurnButton=new Button(width*.2-30, height*.16+width*.15+50, 30, color(100, 50, 50), color(255), null, 'q', true, false, "L T");
  rTurnButton=new Button(width*.2+30, height*.16+width*.15+50, 30, color(50, 100, 50), color(255), null, 'e', true, false, "R T");
  armSelector=new DiamondSelector(width/2, (int)(height*.4), (width/sqrt(2)));
  armBackspaceButton=new Button(width*.15, height*.5, 50, color(100), color(220), null, 0, true, false, "back");
  armCancelButton=new Button(width*.85, height*.5, 50, color(80, 120, 80), color(220), null, 0, true, false, "cancel");
  armStick=new Joystick(width*.8, height*.16, width*.3, 1, 1, color(100, 0, 100), color(255), "X Rotation", "Y Rotation", 'i', 'j', 'k', 'l', 0, 0);
  wristSlider=new Slider(width*.8, height*.23, width*.3, width*.06, -225, 225, color(255, 0, 255), color(255), null, 0, 0, 0, 0, true, true);
  middleSlider=new Slider(width*.49, height*.16, width*.3, width*.05, 0, 1, color(155, 155, 0), color(255), null, 0, 0, 0, 0, false, true);
  rightSlider=new Slider(width*.56, height*.16, width*.3, width*.05, 0, 1, color(0, 200, 0), color(255), null, 0, 0, 0, 0, false, true);
  dropButton=new Button(width*.49-5, height*.16+width*.15+30, 30, color(100, 100, 50), color(200), "Button 4", 0, true, false, "drop");
  grabButton=new Button(width*.56+5, height*.16+width*.15+30, 30, color(50, 100, 100), color(200), "Button 5", 0, true, false, "grab");
  robotCanvas= createGraphics(width, int(height*.25));
  robotCtrlDraw=new RobotDraw(robotCanvas, 600, upperArmLength, forearmLength, handLength, width*.5, 250);
}

void draw() {
  background(0);
  boolean lefthat=false;
  try {
    lefthat=gpad.getHat("cooliehat: Hat Switch").left();
  }
  catch(Exception e) {
  }
  if (lTurnButton.run()||lefthat) {
    lTurnButton.overrideColor=true;
    if (!wasLeftTurnButton) {
      autoTurns+=90;
    }
    wasLeftTurnButton=true;
  } else {
    wasLeftTurnButton=false;
  }
  boolean righthat=false;
  try {
    righthat=gpad.getHat("cooliehat: Hat Switch").right();
  }
  catch(Exception e) {
  }
  if (rTurnButton.run()||righthat) {
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

  armSelector.run();
  drive=driveStick.run(new PVector(0, 0));
  armJog=armStick.run(new PVector(0, 0));
  wristAngleSliderVal+=gamepadVal("Z Axis", 0)*180/frameRate;
  if (gamepadVal("Z Axis", 0)!=0) {
    wristSlider.stick=color(150);
  } else {
    wristSlider.stick=color(255);
  }
  wristAngleSliderVal=wristSlider.run(wristAngleSliderVal);

  armXOut+=0.1/frameRate*armJog.x;
  armYOut+=0.1/frameRate*armJog.y;

  ArmCommandStruct cartArm=cartToAngles(new ArmCommandStruct(armXOut, armYOut, 0, 0, true), armConfig);

  float armEndAngle=+cartArm.theta1+cartArm.theta2;
  while (armEndAngle>180)
    armEndAngle-=360;
  while (armEndAngle<-180)
    armEndAngle+=360;

  armWristOut=wristAngleSliderVal-armEndAngle;

  robotCanvas.beginDraw();
  robotCanvas.background(30, 0, 0);
  robotCanvas.pushMatrix();
  robotCanvas.translate(robotCtrlDraw.shoulderX, robotCtrlDraw.shoulderY);
  robotCanvas.fill(0, 25, 0);
  robotCanvas.circle(0, 0, 2*(armConfig.d1+armConfig.d2)*robotCtrlDraw.pixelsPerMeter);
  robotCanvas.fill(30, 0, 0);
  robotCanvas.circle(0, 0, 2*(max(armConfig.d1, armConfig.d2)-min(armConfig.d1, armConfig.d2))*robotCtrlDraw.pixelsPerMeter);
  robotCanvas.translate(armXOut*robotCtrlDraw.pixelsPerMeter, -armYOut*robotCtrlDraw.pixelsPerMeter);
  robotCanvas.fill(255);
  robotCanvas.circle(armXOut, armYOut, 10);
  robotCanvas.popMatrix();
  robotCanvas.endDraw();
  robotCtrlDraw.draw(cartArm.theta1, cartArm.theta2, constrain(armWristOut, -90, 90));
  image(robotCanvas, 0, height*.55);

  grabButton.run();
  dropButton.run();
  if (grabButton.justPressed()) {
    if (grabState<2)grabState++;
    if (grabState==1) {
      middleAngle = 1;
      rightAngle = 0;
    }
    if (grabState==2) {
      middleAngle = 1;
      rightAngle = 1;
    }
  }
  if (dropButton.justPressed()) {
    if (grabState>0)grabState--;
    if (grabState==1) {
      middleAngle = 1;
      rightAngle = 0;
    }
    if (grabState==0) {
      middleAngle = 0;
      rightAngle = 0;
    }
  }
  middleAngle = middleSlider.run(middleAngle);
  rightAngle = rightSlider.run(rightAngle);

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

  batteryGraph.run(batVolt);
  fill(255);
  textSize(30);
  text(nf(batVolt, 1, 2), width*.73, height*.08);
  textSize(20);
  text("ping: "+nf(wifiPing, 1, 0), width*.05, height*.03);

  String[] msgl={"autoTurn", "wristAngleSliderVal", "cartArm.theta1", "cartArm.theta2"};
  String[] datal={str(autoTurns), str(wristAngleSliderVal), str(cartArm.theta1), str(cartArm.theta2)};
  dispTelem(msgl, datal, width/4, int(height*.9), width/2, int(height*.2), 12);
  String[] msgr={"Ain", "Bin", "Cin", "Din"};
  String[] datar={str(Ain), str(Bin), str(Cin), str(Din)};
  dispTelem(msgr, datar, width*3/4, int(height*.9), width/2, int(height*.2), 12);

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
  sendFl(wristAngleSliderVal);
}

class DiamondSelector {
  int x;
  int y;
  float size;
  color colors[][] = {{#3692FF, #ecdb33}, {#3cdb4e, #d04242}};
  String label[]={"front intake", "", "", "front intake above", "low front scale", "high front scale", "low back scale", "high back scale", "front switch", "rest", "duck", "back switch", "back intake above", "", "", "back intake"};
  int stage;
  byte val;
  boolean wasup;
  boolean wasdown;
  boolean wasleft;
  boolean wasright;
  byte outVal;
  DiamondSelector(int _x, int _y, float _size) {
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
            color t;
            if (outVal==(oi*8+oj*4+ii*2+ij)) {
              c=color(255);
              t=color(0);
            } else if (stage==1&&((val>>2)&3)==oi*2+oj) {
              c=colors[ii][ij];
              t = color(0);
            } else {
              c=colors[ii][ij];
              c=mcb(c, 0.25);
              t=color(255);
            }
            noStroke();
            fill(c);
            float my=(mouseX-x)*sqrt(2)/2.0+(mouseY-y)*sqrt(2)/2.0;
            float mx=-(mouseY-y)*sqrt(2)/2.0+(mouseX-x)*sqrt(2)/2.0;
            if (mousePress&&inDiamond(mx, my, (oj-0.5)*size/2.0+(ij-.5)*size/4.0, (oi-.5)*size/2.0+(ii-.5)*size/4.0, size/8)) {
              stage=2;
              val=(byte)(oi*8+oj*4+ii*2+ij);
            }
            rect((oj-.5)*size/2+(ij-.5)*size/4, (oi-.5)*size/2+(ii-.5)*size/4, size/4, size/4);
            fill(t);
            textSize(size/25);
            textAlign(CENTER, CENTER);
            pushMatrix();
            translate((oj-.5)*size/2+(ij-.5)*size/4, (oi-.5)*size/2+(ii-.5)*size/4);
            rotate(PI/4);
            text(label[(oi*8+oj*4+ii*2+ij)], 0, 0, size/4/sqrt(2), size/4/sqrt(2));
            popMatrix();
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
boolean inDiamond(float inx, float iny, float x, float y, float side) {
  return inx>x-side&&inx<x+side&&iny>y-side&&iny<y+side;
}

color mcb(color c, float f) {//multiply color brightness
  return color(red(c)*f, green(c)*f, blue(c)*f);
}

class RobotDraw {
  PGraphics pg;
  float pixelsPerMeter;
  float upperArmLength;
  float forearmLength;
  float handLength;
  float shoulderX;
  float shoulderY;
  color upperArmColor=color(150, 0, 150);
  color forearmColor=color(255, 0, 0);
  color handColor=color(70, 100, 255);
  RobotDraw(PGraphics _pg, float _pixelsPerMeter, float _upperArmLength, float _forearmLength, float _handLength, float _shoulderX, float _shoulderY) {
    pixelsPerMeter=_pixelsPerMeter;
    upperArmLength=_upperArmLength;
    forearmLength=_forearmLength;
    handLength=_handLength;
    pg=_pg;
    shoulderX=_shoulderX;
    shoulderY=_shoulderY;
  }
  void draw(float shoulderAngle, float elbowAngle, float wristAngle) {
    pg.beginDraw();
    pg.pushStyle();
    pg.strokeWeight(5);
    pg.pushMatrix();
    pg.translate(shoulderX, shoulderY);
    pg.rotate(-radians(shoulderAngle));
    pg.stroke(upperArmColor);
    pg.line(0, 0, 0, -upperArmLength*pixelsPerMeter);
    pg.translate(0, -upperArmLength*pixelsPerMeter);
    pg.rotate(-radians(elbowAngle));
    pg.stroke(forearmColor);
    pg.line(0, 0, 0, -forearmLength*pixelsPerMeter);
    pg.translate(0, -forearmLength*pixelsPerMeter);
    pg.rotate(-radians(wristAngle));
    pg.stroke(handColor);
    pg.line(0, 0, 0, -handLength*pixelsPerMeter);
    pg.popMatrix();
    pg.popStyle();
    pg.endDraw();
  }
}
