/////////////////////////add interface elements here
BatteryGraph batteryGraph;
Joystick driveStick;
Button lTurnButton;
Button rTurnButton;
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

void setup() {
  size(300, 1000);
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
  driveStick=new Joystick(width*.8, height*.2, width*.3, 1, 1, color(0, 100, 0), color(255), "X Axis", "Y Axis", UP, LEFT, DOWN, RIGHT, 0, 0);
  lTurnButton=new Button(width*.7, height*.3, 30, color(100, 50, 50), color(255), null, 'q', true, false, "L T");
  rTurnButton=new Button(width*.9, height*.3, 30, color(50, 100, 50), color(255), null, 'e', true, false, "R T");
}
void draw() {
  background(0);

  if (lTurnButton.run()||gpad.getHat("cooliehat: Hat Switch").left()) {
    if (!wasLeftTurnButton) {
      autoTurns+=90;
    }
    wasLeftTurnButton=true;
  } else {
    wasLeftTurnButton=false;
  }
  if (rTurnButton.run()||gpad.getHat("cooliehat: Hat Switch").right()) {
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
