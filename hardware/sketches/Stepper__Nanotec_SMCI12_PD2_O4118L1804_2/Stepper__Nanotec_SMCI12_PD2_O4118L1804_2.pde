import netP5.*;
import oscP5.*;
import controlP5.*;


OscP5 oscP5;
MotorController mc;
ControlP5 cp5;

public float motor_max_speed = 0.0346; // umdrehung pro sekunde
public float motor_speed_exponent = 1;
public float motor_speed_multiplier = 1;
  public float motor_speed_position_proportion = 1;


void setup() {
  size(1024, 768);

  oscP5 = new OscP5(this, "localhost", 8000);

  printArray(Serial.list());

  cp5 = new ControlP5(this);


  cp5.addSlider("motor_max_speed")
    .setPosition(10, 40)
    .setSize(800, 20)
    .setRange(0, 0.1)
    ;

  cp5.addSlider("motor_speed_multiplier")
    .setPosition(10, 120)
    .setSize(800, 20)
    .setRange(0, 50)

    ;

  cp5.addSlider("motor_speed_exponent")
    .setPosition(10, 200)
    .setSize(800, 20)
    .setRange(0, 2)
    ;

  cp5.addSlider("motor_speed_position_proportion")
    .setPosition(10, 280)
    .setSize(800, 20)
    .setRange(0, 2)
    ;


  // add a vertical slider
  //cp5.addSlider("slider")
  //   .setPosition(100,305)
  //   .setSize(200,20)
  //   .setRange(0,200)
  //   .setValue(128)
  //   ;

  mc = createMotorController("/dev/tty.usbmodem7133801", 12);
}

void oscEvent(OscMessage msg) {
  /* check if theOscMessage has the address pattern we are looking for. */

  if (msg.checkAddrPattern("/mirror")==true) {
    /* check if the typetag is the right one. */
    if (msg.checkTypetag("if")) {
      int motor_id = msg.get(0).intValue();
      /* parse theOscMessage and extract the values from the osc message arguments. */
      float new_motor_position = msg.get(1).floatValue() / 360f;
      mc.setMotorPosition(motor_id, new_motor_position);
      return;
    }
  } else {
    System.out.println(msg);
  }
}

void draw() {
  background(100);
  fill(255);
  text("State: "+ mc.getMotorState(), 10, 20);
  //noLoop();
  mc.motor_max_speed = motor_max_speed;
  mc.motor_speed_exponent = motor_speed_exponent;
  mc.motor_speed_multiplier = motor_speed_multiplier;
  mc.motor_speed_position_proportion = motor_speed_position_proportion;
}



void serialEvent(Serial MOTOR_SERIAL) {
  while (MOTOR_SERIAL.available() > 0) {
    int mRead = MOTOR_SERIAL.read();
    print((char)mRead);
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
  case 'f':
    mc.startMotors();
  case ' ':
    println("read position");
    //sendCo mmand(compileCommand("C")); // 2.5.20 Position auslesen
    break;
  }

  //switch(keyCode) {
  //case DOWN:
  //  println();
  //  print("### reset EEPROM … ");
  //  sendCommand(compileCommand(MOTOR_CMD_EEPROM_RESET));
  //  delay(2000);
  //  println("DONE");
  //  break;
  //}
}
