import processing.serial.*;

public static final String MOTOR_CMD_EEPROM_RESET = "~";            // 2.5.31

Serial MOTOR_SERIAL;
boolean writeSuccess = false;
void setup() {
  size(400, 400);

  printArray(Serial.list());
  String mPortName = "/dev/tty.usbmodem7133801";//Serial.list()[0];
  MOTOR_SERIAL = new Serial(this, mPortName, 115200);
}

void draw() {
  background(255);
  fill(0);
  if (address.length() > 0) {
    text("Address to program: " + address, 10, 20);
  }
  if (writeSuccess) {
    text("Address written!", 10, 20);
  }
}

void serialEvent(Serial MOTOR_SERIAL) {
  while (MOTOR_SERIAL.available() > 0) {
    int mRead = MOTOR_SERIAL.read();
    print((char)mRead);
  }
}

String address = "";

void keyPressed() {
  if (keyCode == ENTER) {
    if (address.length() == 0) return;
    try {
      address = Integer.toString(Integer.valueOf(address));
      println("Set Motor to address: " + address);
      MOTOR_SERIAL.write("#*~\r");
      delay(2000);
      MOTOR_SERIAL.write("#*m"+address+"\r");
      address = "";
      writeSuccess = true;
    }
    catch (NumberFormatException e) {
      address = "";
      println("error", e);
      writeSuccess = false;
    }
  } else {
    address += key;
    writeSuccess = false;
  }
}
