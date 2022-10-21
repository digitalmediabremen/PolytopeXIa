import processing.serial.*;

static class MotorController extends Thread {

  private final Serial MOTOR_SERIAL;

  private float[] current_motor_positions;
  private float[] new_motor_positions;
  public final int NUM_MOTORS;

  public static final int MICRO_STEPS = 32;
  public static final int MAX_SPEED = 1000 * MICRO_STEPS;
  public static final int STEPS_FULL_ROTATION = 200 * MICRO_STEPS;

  public static final int MOTOR_ID_ALL = -1;
  public static final int MOTOR_DELAY_CMD = 10;

  public static final String MOTOR_CMD_PREFIX = "#";
  public static final String MOTOR_CMD_SUFFIX = "\r";
  public static  final String MOTOR_CMD_READ = "Z";

  public static final String MOTOR_CMD_MOTOR_TYPE = ":CL_motor_type"; // 2.5.1
  public static final String MOTOR_CMD_PHASE_CURRENT = "i";           // 2.5.2
  public static final String MOTOR_CMD_PHASE_CURRENT_STILL = "r";     // 2.5.3
  public static final String MOTOR_CMD_STEP_MODE = "g";               // 2.5.6
  public static final String MOTOR_CMD_ADDRESS = "m";                 // 2.5.7
  public static final String MOTOR_CMD_ID = ":mt";                    // 2.5.8
  public static final String MOTOR_CMD_END_SWITCH_BEHAVIOR = "l";     // 2.5.9
  public static final String MOTOR_CMD_ERROR_CORRECTION = "U";        // 2.5.10

  public static final String MOTOR_CMD_STATUS = "$";                  // 2.5.22
  public static final String MOTOR_CMD_FIRMWARE = "v";                // 2.5.23

  public static final String MOTOR_CMD_EEPROM_RESET = "~";            // 2.5.31

  public static final String MOTOR_CMD_START = "A";
  public static final String MOTOR_CMD_STOP = "S";
  public static final String MOTOR_CMD_DIRECTION = "d";

  public static final int VEZER_FPS = 32;

  public float motor_max_speed = 0.0346; // umdrehung pro sekunde
  public float motor_speed_exponent = 1;
  public float motor_speed_multiplier;
  public float motor_ramp = 3000;
  public float motor_speed_position_proportion = 1;

  public static enum S {
    INIT,
      SETUP,
      CALIBRATION,
      CALIBRATION_STARTED,
      FOLLOW,
      ESTOP
  }

  private S state = S.INIT;

  public MotorController(PApplet instance, String serialPortName, int num_motors) {
    MOTOR_SERIAL = new Serial(instance, serialPortName, 115200);
    NUM_MOTORS = num_motors;
    current_motor_positions = new float[num_motors];
    new_motor_positions = new float[num_motors];
  }

  private void motorLoop() {
    while (true) {
      if (state == S.SETUP) {
        sendDefaults();
        state = S.CALIBRATION;
      } else if (state == S.CALIBRATION) {
        startHoming();
        state = S.CALIBRATION_STARTED;
      } else if (state == S.CALIBRATION_STARTED) {
        endHoming();
        state = S.FOLLOW;
      } else if (state == S.FOLLOW) {
        if (follow()) continue;
      } else if (state == S.ESTOP) {
        sendCommand(compileCommand(MOTOR_CMD_STOP));
        delay(500);
      }
      delay(MOTOR_DELAY_CMD);
    }
  }

  public void run() {
    motorLoop();
  }

  public void initialize() {
    state = S.SETUP;
  }

  public void stopMotors() {
    state = S.ESTOP;
  }

  public void startMotors() {
    state = S.FOLLOW;
  }

  public void setMotorPosition(int motorId, float position) {
    if (motorId == 0 || motorId > NUM_MOTORS) return;
    new_motor_positions[motorId - 1] = position;
  }

  public S getMotorState() {
    return state;
  }

  private void startHoming() {
    // set digital in 1 as referenzschalter "7"
    sendCommand(compileCommand(MOTOR_CMD_STOP));
    delay(50);
    sendCommand(compileCommand("!", 1));  // positionierart setzen 2.6.6
    sendCommand(compileCommand("p", 4));  // positionierart setzen 2.6.6
    sendCommand(compileCommand("o", 4000)); // 2.6.9 Maximalfrequenz einstellen
    sendCommand(compileCommand("d", 0)); // 2.6.14 Drehrichtung einstellen

    delay(10);
    sendCommand(compileCommand(MOTOR_CMD_START));
  }

  private void endHoming() {
    delay(15000);
    sendCommand(compileCommand("!", 1));  // positionierart setzen 2.6.6
    sendCommand(compileCommand("p", 2));  // positionierart setzen 2.6.6
    //sendCommand(compileCommand("p", 2));  // positionierart setzen 2.6.6
  }

  private void delay(int delay) {
    try {
      MotorController.sleep(delay);
    }
    catch (InterruptedException e) {
    }
  }

  private boolean follow() {
    boolean commandSend = false;
    for (int i = 0; i < NUM_MOTORS; i++) {

      if (new_motor_positions[i] != current_motor_positions[i]) {
        commandSend = true;
        //println("position from, to", current_motor_positions[i] * 360, new_motor_positions[i] * 360);


        float clipped_new_motor_position = Math.max(-1, Math.min(1, new_motor_positions[i]));
        float motor_position_difference = clipped_new_motor_position - current_motor_positions[i];
        float motor_speed_rev_per_second = min(motor_max_speed, (float)Math.pow(Math.abs(motor_position_difference) * 0.5f, motor_speed_exponent) * 2 * motor_speed_multiplier);
        float motor_max_speed_hz = MICRO_STEPS * 16000;
        int motor_speed = Math.round(motor_speed_rev_per_second * motor_max_speed_hz);
        //println("speed", motor_speed_rev_per_second * 360, motor_speed);

        int motor_position_steps = Math.round(clipped_new_motor_position * STEPS_FULL_ROTATION);
        //sendCommand(compileCommand(i + 1, MOTOR_CMD_STOP)); // stop
        sendCommand(compileCommand(i + 1, "o", motor_speed)); // 2.6.9 Maximalfrequenz einstellen
        current_motor_positions[i] = current_motor_positions[i] + (motor_speed_rev_per_second * Math.signum(motor_position_difference));
        if (Math.abs(current_motor_positions[i] - clipped_new_motor_position) < 0.001) current_motor_positions[i] = clipped_new_motor_position;
        int motor_position_steps_2 = Math.round(current_motor_positions[i] * motor_speed_position_proportion * STEPS_FULL_ROTATION);

        sendCommand(compileCommand(i + 1, "s", motor_position_steps));
        sendCommand(compileCommand(i + 1, MOTOR_CMD_START));
      }
    }

    return commandSend;
  }


  void sendDefaults() {
    sendCommand(compileCommand(MOTOR_CMD_MOTOR_TYPE, 0));
    sendCommand(compileCommand(MOTOR_CMD_PHASE_CURRENT, 30));
    sendCommand(compileCommand(MOTOR_CMD_PHASE_CURRENT_STILL, 20));
    sendCommand(compileCommand(MOTOR_CMD_STEP_MODE, MICRO_STEPS)); // adatpive
    sendCommand(compileCommand(MOTOR_CMD_DIRECTION, 0));
    sendCommand(compileCommand(MOTOR_CMD_END_SWITCH_BEHAVIOR, 17442));
    sendCommand(compileCommand(MOTOR_CMD_ERROR_CORRECTION, 0));

    sendCommand(compileCommand("F", 0)); // 2.5.11 Satz für Autokorrektur
    sendCommand(compileCommand("q", 0)); // 2.5.12 Encoderrichtung
    sendCommand(compileCommand("O", 8)); // 2.5.13 Ausschwingzeit
    sendCommand(compileCommand("X", 2)); // 2.5.14 Maximale Abweichung Drehgeber
    sendCommand(compileCommand(":feed_const_num", 2)); // 2.5.15 Zähler für Vorschubkonstante
    sendCommand(compileCommand(":feed_const_denum", 0)); // 2.5.16 Nenner für Vorschubkonstante
    sendCommand(compileCommand("D", 0)); // 2.5.17 Positionsfehler zurücksetzen
    sendCommand(compileCommand("K", 20)); // 2.5.28 Debounce-Zeit für Eingänge setzen (Entprellen)
    sendCommand(compileCommand("Y", 0)); // 2.5.29 Ausgänge setzen
    sendCommand(compileCommand("J", 0)); // 2.5.32 Automatisches Senden des Status einstellen
    sendCommand(compileCommand("z", 0)); // 2.5.34 Umkehrspiel einstellen
    sendCommand(compileCommand(":ramp_mode", 0)); // 2.5.35 Rampe setzen
    sendCommand(compileCommand(":brake_ta", 0)); // 2.5.38 Wartezeit für Abschalten der Bremsspannung setzen
    sendCommand(compileCommand(":brake_tb", 0)); // 2.5.39 Wartezeit für Motorbewegung setzen
    sendCommand(compileCommand(":brake_tc", 0)); // 2.5.40 Wartezeit für Abschalten Motorstrom setzen
    sendCommand(compileCommand(":baud", 12)); // 2.5.41 Baudrate der Steuerung setzen
    sendCommand(compileCommand(":crc", 0)); // 2.5.42 CRC-Prüfsumme einstellen
    sendCommand(compileCommand(":cal_elangle_enable", 0)); // 2.5.43 Korrektur der Sinus-Kommutierung einstellen
    sendCommand(compileCommand(":cal_elangle_data", 0)); // 2.5.44 Elektrischen Winkel setzen

    //sendCommand(compileCommand("y", 1)); // 2.6.3 Satz aus EEPROM laden
    //sendCom mand(compileCommand("|", 1)); // 2.6.4 Aktuellen Satz auslesen
    sendCommand(compileCommand("p", 2)); // 2.6.6 Positionierart setzen
    sendCommand(compileCommand("s", 0)); // 2.6.7 Verfahrweg einstellen **HOW TO DEACTIVATE THIS? with `W`**
    sendCommand(compileCommand("u", 1)); // 2.6.8 Minimalfrequenz einstellen
    sendCommand(compileCommand("o", 4000)); // 2.6.9 Maximalfrequenz einstellen
    sendCommand(compileCommand("b", 3000)); // 2.6.11 Beschleunigungsrampe einstellen
    sendCommand(compileCommand("B", 3000)); // 2.6.12 Bremsrampe einstellen
    sendCommand(compileCommand(":b", 0)); // 2.5.36 Ruck für Beschleunigungsrampe einstellen
    sendCommand(compileCommand("H", 0)); // 2.6.13 Halterampe einstellen
    sendCommand(compileCommand(":B", 0)); // 2.6.12 Ruck für Bremsrampe einstellen
    sendCommand(compileCommand("H", 0)); // 2.6.13 Halterampe einstellen
    sendCommand(compileCommand("d", 0)); // 2.6.14 Drehrichtung einstellen
    sendCommand(compileCommand("t", 0)); // 2.6.15 Richtungsumkehr einstellen
    sendCommand(compileCommand("p", 2));  // positionierart setzen 2.6.6

    sendCommand(compileCommand(":port_in_a", 7));
    // endschalterverhalten setzen
    // bitmask 0100010000100010 as int is 17442
    sendCommand(compileCommand("l", 17442));



    delay(100);
  }

  String compileCommand(int pMotorID, String pCMD) {
    return MOTOR_CMD_PREFIX + (pMotorID == -1 ? "*" : pMotorID) + pCMD + MOTOR_CMD_SUFFIX;
  }

  String compileCommand(String pCMD) {
    return compileCommand(MOTOR_ID_ALL, pCMD);
  }

  String compileCommand(int pMotorID, String pCMD, int pValue) {
    return MOTOR_CMD_PREFIX + (pMotorID == -1 ? "*" : pMotorID) + pCMD + pValue + MOTOR_CMD_SUFFIX;
  }

  String compileCommand(String pCMD, int pValue) {
    return compileCommand(MOTOR_ID_ALL, pCMD, pValue);
  }

  String getMotorID(int pMotorID) {
    return (pMotorID == -1 ? "*" : Integer.toString(pMotorID));
  }

  void sendCommand(String pCommand) {
    MOTOR_SERIAL.write(pCommand);
    delay(MOTOR_DELAY_CMD);
  }
}

MotorController createMotorController(String portName, int numMotors) {
  MotorController mc = new MotorController(this, portName, numMotors);
  new Thread(mc).start();
  return mc;
}
