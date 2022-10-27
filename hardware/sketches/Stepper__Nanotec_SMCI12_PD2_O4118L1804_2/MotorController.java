import java.util.Arrays;
import processing.core.PApplet;
import static processing.core.PApplet.println;
import processing.serial.*;

public class MotorController extends Thread {
  private float[] set_motor_positions;
  private float[] set_motor_rotation_speed;

  private int[] current_motor_positions;
  private float[] new_values;
  private boolean[] is_motor_referenced;
  private PositionMode[] current_position_mode;
  private PositionMode[] new_position_mode;
  private boolean[] motor_disabled;

  private CommandController cc;


  public final int NUM_MOTORS;

  public static final int MICRO_STEPS = 64;
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

  public float motor_position_mode_max_speed = 0.5f; // umdrehung pro sekunde
  public float motor_rotation_mode_max_speed = 0.2f; // umdrehung pro sekunde

  private static enum S {
    INIT,
      SETUP,
      CALIBRATION,
      CALIBRATION_STARTED,
      FOLLOW,
      ESTOP
  }
  
  public static enum PositionMode {
    NOT_SET, CONTINOUS_ROTATION, ABSOLUTE_POSITION
  }

  private S state = S.SETUP;

  public MotorController(PApplet instance, String serialPortName, int num_motors) {
    cc = new CommandController(instance, this, serialPortName);
    NUM_MOTORS = num_motors;
    set_motor_positions = new float[num_motors];
    set_motor_rotation_speed = new float[num_motors];
    new_values = new float[num_motors];
    current_motor_positions = new int[num_motors];
    is_motor_referenced = new boolean[num_motors];
    current_position_mode = new PositionMode[num_motors];
    new_position_mode = new PositionMode[num_motors];
    motor_disabled = new boolean[num_motors];
    Arrays.fill(new_position_mode, PositionMode.NOT_SET);
  }

  private void motorLoop() throws CommandController.CommandTimedOutException {
    while (true) {
      if (state == S.SETUP) {
        sendDefaults();
        state = S.CALIBRATION;
      } else if (state == S.CALIBRATION) {
        starthoming2();
        state = S.CALIBRATION_STARTED;
      } else if (state == S.CALIBRATION_STARTED) {
        endHoming2();
      } else if (state == S.FOLLOW) {
        if (follow()) continue;
      } else if (state == S.ESTOP) {
        cc.sendCommand(MOTOR_CMD_STOP);
        delay(500);
      }
    }
  }

  public void run() {
    try {
      motorLoop();
    }
    catch ( CommandController.CommandTimedOutException e) {
      println(e);
      println("Motor thread exited because of timeout");
      return;
    }
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
    new_values[motorId - 1] = position;
  }

  public void setMotorPositionMode(int motorId, PositionMode mode) {
    if (motorId == 0 || motorId > NUM_MOTORS) return;
    new_position_mode[motorId - 1] = mode;
  }

  public S getMotorState() {
    return state;
  }

  private void starthoming2() throws CommandController.CommandTimedOutException {
    for (int i = 0; i < NUM_MOTORS; i++) {
      if (motor_disabled[i]) continue;
      boolean isMotorReferenced = cc.sendCommand(i + 1, ":is_referenced") == 1;
      if (isMotorReferenced) continue;
      cc.sendCommand(i+1, MOTOR_CMD_STOP);
      cc.sendCommand(i+1, "D"); // 2.5.17 Positionsfehler zurücksetzen
      cc.sendCommand(i+1, ":port_in_a", 7);
      // endschalterverhalten setzen
      // bitmask 0100010000100010 as int is 17442
      cc.sendCommand(i+1, "l", 17442);
      cc.sendCommand(i+1, "p", 4);  // positionierart setzen 2.6.6
      cc.sendCommand(i+1, "u", 100); // 2.6.8 Minimalfrequenz einstellen
      cc.sendCommand(i+1, "d", 0); // 2.6.14 Drehrichtung einstellen
      cc.sendCommand(i+1, MOTOR_CMD_START);
    }
  }

  private void endHoming2() throws CommandController.CommandTimedOutException {
    boolean all_referenced = true;
    for (int i = 0; i < NUM_MOTORS; i++) {
      if (motor_disabled[i]) continue;
      boolean isMotorReferenced = cc.sendCommand(i + 1, ":is_referenced") == 1;
      if (!isMotorReferenced) all_referenced = false;
      else cc.sendCommand(i+1, "p", 2);  // positionierart setzen 2.6.6
      is_motor_referenced[i] = isMotorReferenced;
    }
    if (all_referenced) {
      state = S.FOLLOW;
    }
    delay(100);
  }

  public void delay(int delay) {
    try {
      MotorController.sleep(delay);
    }
    catch (InterruptedException e) {
    }
  }

  private boolean follow() throws CommandController.CommandTimedOutException {
    boolean commandSend = false;

    for (int i = 0; i < NUM_MOTORS; i++) {
      if (motor_disabled[i]) continue;

      // update motor position
      current_motor_positions[i] = cc.sendCommand(i + 1, "C");

      if (current_position_mode[i] != new_position_mode[i]) {

        if (new_position_mode[i] == PositionMode.CONTINOUS_ROTATION) {
          cc.sendCommand(i + 1, MOTOR_CMD_STOP);
          cc.sendCommand(i + 1, "p", 5);
          cc.sendCommand(i + 1, "o", 10); // 2.6.9 Maximalfrequenz einstellen
          set_motor_rotation_speed[i] = 0;
          cc.sendCommand(i + 1, MOTOR_CMD_START);
          current_position_mode[i] = PositionMode.CONTINOUS_ROTATION;
        } else if (new_position_mode[i] == PositionMode.ABSOLUTE_POSITION) {
          cc.sendCommand(i + 1, MOTOR_CMD_STOP);
          cc.sendCommand(i + 1, "p", 2);
          cc.sendCommand(i + 1, "o", 1000); // 2.6.9 Maximalfrequenz einstellen
          int currentMotorPosition = cc.sendCommand(i + 1, "C");
          set_motor_positions[i] = ( currentMotorPosition % STEPS_FULL_ROTATION) / (float)STEPS_FULL_ROTATION;
          cc.sendCommand(i + 1, "D", currentMotorPosition % STEPS_FULL_ROTATION); // 2.5.17 Positionsfehler zurücksetzen
          current_position_mode[i] = PositionMode.ABSOLUTE_POSITION;
        }
      }

      if (current_position_mode[i] == PositionMode.ABSOLUTE_POSITION) {
        // rotate event
        //if (is_motor_referenced[i] != 2) continue;

        if (new_values[i] != set_motor_positions[i]) {
          commandSend = true;
          //println("position from, to", set_motor_positions[i] * 360, new_motor_positions[i] * 360);
          float clipped_new_motor_position = Math.max(-1, Math.min(1, new_values[i]));
          float motor_position_difference = clipped_new_motor_position - set_motor_positions[i];
          float motor_speed_rev_per_second = Math.abs(motor_position_difference * 0.5f) * motor_position_mode_max_speed;
          float motor_max_speed_hz = MICRO_STEPS * 16000;
          int motor_speed = Math.round(motor_speed_rev_per_second * motor_max_speed_hz);

          int motor_position_steps = Math.round(clipped_new_motor_position * STEPS_FULL_ROTATION);
          cc.sendCommand(i + 1, "o", motor_speed); // 2.6.9 Maximalfrequenz einstellen
          cc.sendCommand(i + 1, "s", motor_position_steps);
          cc.sendCommand(i + 1, MOTOR_CMD_START);
          set_motor_positions[i] = clipped_new_motor_position;
        }
      } else if (current_position_mode[i] == PositionMode.CONTINOUS_ROTATION) {
        if (new_values[i] != set_motor_rotation_speed[i]) {
          commandSend = true;
          //println("position from, to", set_motor_positions[i] * 360, new_motor_positions[i] * 360);
          float clipped_new_value = Math.max(-1, Math.min(1, new_values[i]));
          float motor_speed_rev_per_second = Math.abs(clipped_new_value * 0.5f) * motor_rotation_mode_max_speed;
          float motor_max_speed_hz = MICRO_STEPS * 16000;
          int motor_speed = Math.round(motor_speed_rev_per_second * motor_max_speed_hz);
          cc.sendCommand(i+1, "d", clipped_new_value > 0 ? 1 : 0); // 2.6.14 Drehrichtung einstellen
          cc.sendCommand(i + 1, "o", motor_speed); // 2.6.9 Maximalfrequenz einstellen
          set_motor_rotation_speed[i] = new_values[i];
        }
      }
    }

    return commandSend;
  }


  void sendDefaults() {
    for (int i = 1; i < NUM_MOTORS + 1; i++) {
      try {
        cc.sendCommand(i, MOTOR_CMD_MOTOR_TYPE, 0);
        cc.sendCommand(i, MOTOR_CMD_PHASE_CURRENT, 30);
        cc.sendCommand(i, MOTOR_CMD_PHASE_CURRENT_STILL, 20);
        cc.sendCommand(i, MOTOR_CMD_STEP_MODE, MICRO_STEPS); // adatpive
        cc.sendCommand(i, MOTOR_CMD_DIRECTION, 0);
        cc.sendCommand(i, MOTOR_CMD_END_SWITCH_BEHAVIOR, 17442);
        cc.sendCommand(i, MOTOR_CMD_ERROR_CORRECTION, 0);

        cc.sendCommand(i, "F", 0); // 2.5.11 Satz für Autokorrektur
        cc.sendCommand(i, "q", 0); // 2.5.12 Encoderrichtung
        cc.sendCommand(i, "O", 8); // 2.5.13 Ausschwingzeit
        cc.sendCommand(i, "X", 2); // 2.5.14 Maximale Abweichung Drehgeber
        cc.sendCommand(i, ":feed_const_num", 2); // 2.5.15 Zähler für Vorschubkonstante
        cc.sendCommand(i, ":feed_const_denum", 0); // 2.5.16 Nenner für Vorschubkonstante
        cc.sendCommand(i, "D", 0); // 2.5.17 Positionsfehler zurücksetzen
        cc.sendCommand(i, "K", 20); // 2.5.28 Debounce-Zeit für Eingänge setzen (Entprellen)
        cc.sendCommand(i, "Y", 0); // 2.5.29 Ausgänge setzen
        cc.sendCommand(i, "J", 0); // 2.5.32 Automatisches Senden des Status einstellen
        cc.sendCommand(i, "z", 0); // 2.5.34 Umkehrspiel einstellen
        cc.sendCommand(i, ":ramp_mode", 0); // 2.5.35 Rampe setzen
        cc.sendCommand(i, ":brake_ta", 0); // 2.5.38 Wartezeit für Abschalten der Bremsspannung setzen
        cc.sendCommand(i, ":brake_tb", 0); // 2.5.39 Wartezeit für Motorbewegung setzen
        cc.sendCommand(i, ":brake_tc", 0); // 2.5.40 Wartezeit für Abschalten Motorstrom setzen
        cc.sendCommand(i, ":baud", 12); // 2.5.41 Baudrate der Steuerung setzen
        cc.sendCommand(i, ":crc", 0); // 2.5.42 CRC-Prüfsumme einstellen
        cc.sendCommand(i, ":cal_elangle_enable", 0); // 2.5.43 Korrektur der Sinus-Kommutierung einstellen
        cc.sendCommand(i, ":cal_elangle_data", 0); // 2.5.44 Elektrischen Winkel setzen

        //cc.sendCommand("y", 1); // 2.6.3 Satz aus EEPROM laden
        //sendCom mand("|", 1); // 2.6.4 Aktuellen Satz auslesen
        cc.sendCommand(i, "p", 2); // 2.6.6 Positionierart setzen
        cc.sendCommand(i, "s", 0); // 2.6.7 Verfahrweg einstellen **HOW TO DEACTIVATE THIS? with `W`**
        cc.sendCommand(i, "u", 2000); // 2.6.8 Minimalfrequenz einstellen
        cc.sendCommand(i, "o", 4000); // 2.6.9 Maximalfrequenz einstellen
        cc.sendCommand(i, "b", 6000); // 2.6.11 Beschleunigungsrampe einstellen
        cc.sendCommand(i, "B", 6000); // 2.6.12 Bremsrampe einstellen
        cc.sendCommand(i, ":b", 0); // 2.5.36 Ruck für Beschleunigungsrampe einstellen
        cc.sendCommand(i, "H", 0); // 2.6.13 Halterampe einstellen
        cc.sendCommand(i, ":B", 0); // 2.6.12 Ruck für Bremsrampe einstellen
        cc.sendCommand(i, "H", 0); // 2.6.13 Halterampe einstellen
        cc.sendCommand(i, "d", 0); // 2.6.14 Drehrichtung einstellen
        cc.sendCommand(i, "t", 0); // 2.6.15 Richtungsumkehr einstellen
      }
      catch (CommandController.CommandTimedOutException e) {
        println(e);
        motor_disabled[i - 1] = true;
      }

      delay(100);
    }
  }

  public boolean isMotorReferenced(int motorId) {
    return is_motor_referenced[motorId];
  }

  public boolean isMotorDisabled(int motorId) {
    return motor_disabled[motorId];
  }

  public float getCurrentMotorPosition(int motorId) {
        return current_motor_positions[motorId];
  }
  
  public float getPlannedMotorPosition(int motorId) {
    return set_motor_positions[motorId];
  }
  
  public PositionMode getCurrentPositionMode(int motorId) {
    return current_position_mode[motorId];
  }
  
  public void forwardSerialEvent(Serial s) {
    this.cc.serialEvent(s);
  }

  public static MotorController createInstance(PApplet instance, String portName, int numMotors) {
    MotorController mc = new MotorController(instance, portName, numMotors);
    new Thread(mc).start();
    return mc;
  }
}
