import netP5.*;
import oscP5.*;
import controlP5.*;
import processing.serial.*;


OscP5 oscP5;
MotorController mc;
ControlP5 cp5;

public float motor_position_mode_max_speed = 0.5; // umdrehung pro sekunde
public float motor_rotation_mode_max_speed = 0.02; // umdrehung pro sekunde

int xp = 100;

void setup() {
  size(1024, 400);

  oscP5 = new OscP5(this, 8000);
  cp5 = new ControlP5(this);


  cp5.addSlider("motor_position_mode_max_speed")
    .setPosition(xp - 20, 40)
    .setSize(width / 2, 20)
    .setRange(0, 1)
    ;

  cp5.addSlider("motor_rotation_mode_max_speed")
    .setPosition(xp - 20, 90)
    .setSize(width / 2, 20)
    .setRange(0, 0.05)
    ;
    
  CommandController.listSerialDevices();
  mc = MotorController.createInstance(this, "/dev/tty.usbmodem6550801", 12);
}

void oscEvent(OscMessage msg) {
  /* check if theOscMessage has the address pattern we are looking for. */

  if (msg.checkAddrPattern("/motor/position")==true) {
    /* check if the typetag is the right one. */
    if (msg.checkTypetag("if")) {
      int motor_id = msg.get(0).intValue();
      /* parse theOscMessage and extract the values from the osc message arguments. */
      float new_motor_position = msg.get(1).floatValue() / 360f;
      mc.setMotorPositionMode(motor_id, MotorController.PositionMode.ABSOLUTE_POSITION);
      mc.setMotorPosition(motor_id, new_motor_position);
      return;
    }
    //} else if (msg.checkTypetag("f")) {
    //  /* parse theOscMessage and extract the values from the osc message arguments. */
    //  float new_motor_position = msg.get(0).floatValue() / 360f;
    //  for (int i = 0; i < mc.NUM_MOTORS; i++) {
    //    mc.setMotorPositionMode(i + 1, 0);
    //    mc.setMotorPosition(i + 1, new_motor_position);
    //  }
    //  return;
    //}
  } else if (msg.checkAddrPattern("/motor/rotation")==true) {
    /* check if the typetag is the right one. */
    if (msg.checkTypetag("if")) {
      int motor_id = msg.get(0).intValue();
      /* parse theOscMessage and extract the values from the osc message arguments. */
      float new_motor_position = msg.get(1).floatValue() / 360f;
      mc.setMotorPositionMode(motor_id, MotorController.PositionMode.CONTINOUS_ROTATION);
      mc.setMotorPosition(motor_id, new_motor_position);
      return;
    }
    //} else if (msg.checkTypetag("f")) {
    //  /* parse theOscMessage and extract the values from the osc message arguments. */
    //  float new_motor_position = msg.get(0).floatValue() / 360f;
    //  for (int i = 0; i < mc.NUM_MOTORS; i++) {
    //    mc.setMotorPositionMode(i + 1, 1);
    //    mc.setMotorPosition(i + 1, new_motor_position);
    //  }
    //  return;
    //}
  } else {
    System.out.println(msg);
  }
}

void draw() {
  background(100);
  fill(255);
  textAlign(LEFT, CENTER);

  text("State: "+ mc.getMotorState(), 10, 20);
  textAlign(CENTER, CENTER);
  //noLoop();
  mc.motor_position_mode_max_speed = motor_position_mode_max_speed;
  mc.motor_rotation_mode_max_speed = motor_rotation_mode_max_speed;

  int y = height - 100;
  int yt = height - 150;
  int ys = height - 50;
  int ypm = height - 30;
  rectMode(CENTER);

  for (int i = 0; i < mc.NUM_MOTORS; i++) {
    color c = mc.isMotorReferenced(i) ? color(0, 255, 0) : !mc.isMotorDisabled(i) ? color(255, 255, 255): color(255, 0, 0);
    float x = map(i, 0, mc.NUM_MOTORS - 1, xp, width - xp);
    float v = map(mc.getCurrentMotorPosition(i), -MotorController.STEPS_FULL_ROTATION, MotorController.STEPS_FULL_ROTATION, -TWO_PI, +TWO_PI);
    float v2 = map(mc.getPlannedMotorPosition(i), -1, +1, -TWO_PI, +TWO_PI);
    fill(c);
    noStroke();
    circle(x, ys, 10);
    fill(255);
    text("M" + (i + 1), x, yt);
    text(mc.getCurrentPositionMode(i) == MotorController.PositionMode.ABSOLUTE_POSITION ? "POS" : "ROT", x, ypm);

    float _x = cos(v) * 20;
    float _y = sin(v) * 20;
    float _x2 = cos(v2) * 20;
    float _y2 = sin(v2) * 20;
    fill(0);
    stroke(0);
    circle(x, y, 40);
    strokeWeight(3);
    if (mc.getCurrentPositionMode(i) != MotorController.PositionMode.CONTINOUS_ROTATION) {
      stroke(150);
      line(x, y, x + _x2, y + _y2);
    }
    stroke(255);
    line(x, y, x + _x, y + _y);
    strokeWeight(1);
  }
}


void keyPressed() {
  switch(key) {
  case 'S':
    mc.initialize();
    break;
  case 's':
    mc.stopMotors();
    break;
  case ' ':
    println("read position");
    //sendCo mmand(compileCommand("C")); // 2.5.20 Position auslesen
    break;
  }
}

// this is a hack as classes cant register to listen for serial events through the registerCommand interface.
public void serialEvent(Serial MOTOR_SERIAL) {
  mc.forwardSerialEvent(MOTOR_SERIAL);
}
