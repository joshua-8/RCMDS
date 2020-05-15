int wifiPort=25210;
String wifiIP="73.37.49.126";
///////////////////////////////
Joystick stick1;
Joystick stick2;
Button b1;
Button b2;
Button b3;

float batVolt=0.0;
boolean enabled=false;
void setup() {
  //fullScreen();//remove for Java mode
  size(1920, 1080);//remove for Android mode
  rcmdsSetup();
  setupGamepad("Feather 32u4");//name of gamepad device, remove for Android mode
  //touchscreen=new Touchscreen();//remove for Java mode
  mousescreen=new Mousescreen();//remove for Android mode
  keyboardCtrl=new KeyboardCtrl();//remove for Android mode
  //setupAccelerometer();//remove for Java mode
  //setup UI
  stick1=new Joystick(1500, 500, 500, 10, 20, color(255, 0, 0), color(255), "X Axis", "Y Axis", 'w', 'a', 's', 'd', 0, TILT_Y);
  stick2=new Joystick(500, 500, 500, 10, 20, color(0, 255, 0), color(255, 0, 255), null, null, UP, 0, DOWN, 0, TILT_Y, TILT_X);
  b1=new Button(1000, 100, 100, color(100), color(0, 200, 0), "Button 1", ' ', true, false);
  b2=new Button(1000, 300, 100, color(100), color(0, 200, 0), "Button 2", SHIFT, false, true);
  b3=new Button(1000, 500, 100, color(100), color(0, 200, 0), "Button 3", 0, false, false);
}
void draw() {
  background(0);
  stick1.run(new PVector(0, -20));
  stick2.run(new PVector(0, 0));
  b1.run();
  b2.run();
  b3.run();
  String[] msg={"battery voltage"};
  String[] data={str(batVolt)};
  dispTelem(msg, data, width/8, height/9, width/4, height*1/5, 20);

  mousePress=false;//remove for Android mode
  sendWifiData(true);
}
void WifiDataToParse() {
  batVolt=parseFl();
  //add data to read here
}
void WifiDataToSend() {
  addBoolean(enabled);
  //add data to send here
}
