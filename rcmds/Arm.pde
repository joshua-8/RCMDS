class ArmCommandStruct {
  float x;
  float y;
  float theta1;
  float theta2;
  boolean bendElbowPos;
  ArmCommandStruct(float _x, float _y, float _theta1, float _theta2, boolean _bendElbowPos) {
    x = _x;
    y = _y;
    theta1 = _theta1;
    theta2 = _theta2;
    bendElbowPos = _bendElbowPos;
  }
}
class ArmConfigStruct {
  float d1;
  float d2;
  // float theta1Min;
  // float theta1Max;
  // float theta2Min;
  // float theta2Max;
  ArmConfigStruct(float _d1, float _d2) {
    d1=_d1;
    d2=_d2;
  }
}

ArmCommandStruct cartToAngles(ArmCommandStruct command, ArmConfigStruct config)
{
  float theta2 = PI - acos((-sq(command.x) - sq(command.y) + sq(config.d1) + sq(config.d2)) / (2 * config.d1 * config.d2));
  if (command.bendElbowPos) {
    theta2 = -theta2;
  }
  while (theta2>PI)
    theta2-=PI;
  while (theta2<-PI)
    theta2+=PI;

  float theta1=-PI/2+atan2(-command.x, command.y)+atan2(config.d2*cos(theta2)+config.d1, config.d2*sin(theta2));
  while (theta1>PI)
    theta1-=TWO_PI;
  while (theta1<-PI)
    theta1+=TWO_PI;

  theta1 = degrees(theta1);
  theta2 = degrees(theta2);
  //if (isnan(theta1) || isnan(theta2) || theta1 < theta1Min || theta1 > theta1Max || theta2 < theta2Min || theta2 > theta2Max) {
  //  return false;
  //}
  return new ArmCommandStruct(command.x, command.y, theta1, theta2, command.bendElbowPos);
}
boolean isnan(float v) {
  return Float.isNaN(v);
}
