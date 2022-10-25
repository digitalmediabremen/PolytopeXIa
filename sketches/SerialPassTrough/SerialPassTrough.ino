/*

  SerialPassthrough sketch

  Some boards, like the Arduino 101, the MKR1000, Zero, or the Micro, have one

  hardware serial port attached to Digital pins 0-1, and a separate USB serial

  port attached to the IDE Serial Monitor. This means that the "serial

  passthrough" which is possible with the Arduino UNO (commonly used to interact

  with devices/shields that require configuration via serial AT commands) will

  not work by default.

  This sketch allows you to emulate the serial passthrough behaviour. Any text

  you type in the IDE Serial monitor will be written out to the serial port on

  Digital pins 0 and 1, and vice-versa.

  On the 101, MKR1000, Zero, and Micro, "Serial" refers to the USB Serial port

  attached to the Serial Monitor, and "Serial1" refers to the hardware serial

  port attached to pins 0 and 1. This sketch will emulate Serial passthrough

  using those two Serial ports on the boards mentioned above, but you can change

  these names to connect any two serial ports on a board that has multiple ports.

  created 23 May 2016

  by Erik Nyquist

*/

// for TEENSY 3.1+3.2 use Serial3 (PIN07>RX, PIN08>TX)
#define MOTOR_SERIAL Serial3

void setup() {
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, HIGH);

  Serial.begin(115200);
  Serial.println(__DATE__);
  Serial.println(__TIME__);

  MOTOR_SERIAL.begin(115200);
}

void loop() {

  if (Serial.available()) {
    MOTOR_SERIAL.write(Serial.read());
  }

  if (MOTOR_SERIAL.available()) {
    digitalWrite(LED_BUILTIN, HIGH);
    int c = MOTOR_SERIAL.read();
    Serial.write(c);
  } else {
    digitalWrite(LED_BUILTIN, LOW);
  }
}
