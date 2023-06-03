EnableSwitch enableSwitch;
int TILT_X=1;
int TILT_Y=2;
void rcmdsSetup() {
  orientation(LANDSCAPE);
  shapeMode(CENTER);
  rectMode(CENTER);
  background(0);
  mousescreen=new Mousescreen();
  keyboardCtrl=new KeyboardCtrl();
  udp = new UDP(this);
  udp.listen(true);
  enableSwitch=new EnableSwitch(width*3/4, height*.025, width/2-4, height/25);
}
void endOfDraw() {
  mousePress=false;
}
