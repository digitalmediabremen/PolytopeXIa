// for TEENSY 3.1+3.2 use Serial3 (PIN07>RX, PIN08>TX)
#define MOTOR_SERIAL Serial3

String CMD_START = String("#*A\r");
String CMD_STOP = String("#*S1\r");
bool fToggle;

void setup() {
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, HIGH);

  Serial.begin(115200);
  Serial.println(__DATE__);
  Serial.println(__TIME__);

  MOTOR_SERIAL.begin(115200);
  MOTOR_SERIAL.print("MOTOR_SERIAL");
}

void loop() {
  /* start motor */
  digitalWrite(LED_BUILTIN, HIGH);
  MOTOR_SERIAL.print(CMD_START);
  delay(500);

  /* stop motor */
  digitalWrite(LED_BUILTIN, LOW);
  MOTOR_SERIAL.print(CMD_STOP);
  delay(500);

  /* print motor response */
  while (MOTOR_SERIAL.available() > 0) {
    int c = MOTOR_SERIAL.read();
    Serial.write(c);
    fToggle = !fToggle;
    digitalWrite(LED_BUILTIN, fToggle);
  }
  Serial.println("\n---");
}
