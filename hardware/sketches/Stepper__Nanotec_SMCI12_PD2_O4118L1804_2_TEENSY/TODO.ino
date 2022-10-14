// TODO make this into a library 
// - [ ] convert java to c++
// - [ ] add pass-through option
// - [ ] add motor message handling

/*
void sendDefaults() {
    sendCommand(compileCommand(MOTOR_CMD_MOTOR_TYPE, 0));
    sendCommand(compileCommand(MOTOR_CMD_PHASE_CURRENT, 20));
    sendCommand(compileCommand(MOTOR_CMD_PHASE_CURRENT_STILL, 20));
    sendCommand(compileCommand(MOTOR_CMD_STEP_MODE, 2));
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
    sendCommand(compileCommand(":b", 1)); // 2.5.36 Maximalen Ruck für Beschleunigungsrampe setzen
    sendCommand(compileCommand(":B", 0)); // 2.5.37 Maximalen Ruck für Bremsrampe setzen
    sendCommand(compileCommand(":brake_ta", 0)); // 2.5.38 Wartezeit für Abschalten der Bremsspannung setzen
    sendCommand(compileCommand(":brake_tb", 0)); // 2.5.39 Wartezeit für Motorbewegung setzen
    sendCommand(compileCommand(":brake_tc", 0)); // 2.5.40 Wartezeit für Abschalten Motorstrom setzen
    sendCommand(compileCommand(":baud", 12)); // 2.5.41 Baudrate der Steuerung setzen
    sendCommand(compileCommand(":crc", 0)); // 2.5.42 CRC-Prüfsumme einstellen
    sendCommand(compileCommand(":cal_elangle_enable", 0)); // 2.5.43 Korrektur der Sinus-Kommutierung einstellen
    sendCommand(compileCommand(":cal_elangle_data", 0)); // 2.5.44 Elektrischen Winkel setzen

    sendCommand(compileCommand("y", 1)); // 2.6.3 Satz aus EEPROM laden
    sendCommand(compileCommand("|", 1)); // 2.6.4 Aktuellen Satz auslesen
    sendCommand(compileCommand(">", 1)); // 2.6.5 Satz speichern
    sendCommand(compileCommand("p", 1)); // 2.6.6 Positionierart setzen
    sendCommand(compileCommand("s", 800)); // 2.6.7 Verfahrweg einstellen **HOW TO DEACTIVATE THIS? with `W`**
    sendCommand(compileCommand("u", 1)); // 2.6.8 Minimalfrequenz einstellen
    sendCommand(compileCommand("o", 800)); // 2.6.9 Maximalfrequenz einstellen
    sendCommand(compileCommand("b", 1)); // 2.6.11 Beschleunigungsrampe einstellen
    sendCommand(compileCommand("B", 0)); // 2.6.12 Bremsrampe einstellen
    sendCommand(compileCommand("H", 0)); // 2.6.13 Halterampe einstellen
    sendCommand(compileCommand("d", 0)); // 2.6.14 Drehrichtung einstellen  
    sendCommand(compileCommand("t", 0)); // 2.6.15 Richtungsumkehr einstellen  
    sendCommand(compileCommand("W", 0)); // 2.6.16 Wiederholungen einstellen 
    sendCommand(compileCommand("P", 0)); // 2.6.17 Satzpause einstellen
    sendCommand(compileCommand("N", 0)); // 2.6.18 Folgesatz einstellen
    
    delay(500);
    sendCommand(compileCommand(MOTOR_CMD_START));
}

void draw() {
    background(255);
}

void serialEvent(Serial MOTOR_SERIAL) {
    while (MOTOR_SERIAL.available() > 0) {
        int mRead = MOTOR_SERIAL.read();
        print((char)mRead);
    }
}

public static final int MOTOR_ID_ALL = -1;
public static final int MOTOR_DELAY_CMD = 50;

public static final String MOTOR_CMD_PREFIX = "#";
public static final String MOTOR_CMD_SUFFIX = "\r";
public static final String MOTOR_CMD_READ = "Z";

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

void keyPressed() {
    switch(key) {
    case 's':
        sendCommand(compileCommand(MOTOR_CMD_START));
        break;
    case 'S':
        sendCommand(compileCommand(MOTOR_CMD_STOP, 1));
        break;
    case 'i':
        sendCommand(compileCommand(MOTOR_CMD_PHASE_CURRENT, 10));
        break;
    case 'I':
        sendCommand(compileCommand(MOTOR_CMD_PHASE_CURRENT, 50));
        break;
    case 'd':
        sendCommand(compileCommand(MOTOR_CMD_DIRECTION, 0));
        break;
    case 'D':
        sendCommand(compileCommand(MOTOR_CMD_DIRECTION, 1));
        break;
    case 'g':
        sendCommand(compileCommand(MOTOR_CMD_STEP_MODE, 2));
        break;
    case 'G':
        sendCommand(compileCommand(MOTOR_CMD_STEP_MODE, 64));
        break;
    case 'm':
        sendCommand(compileCommand(MOTOR_CMD_ADDRESS, 1));
        break;
    case 'M':
        sendCommand(compileCommand(MOTOR_CMD_READ + MOTOR_CMD_ADDRESS));
        break;
    case ' ':
        sendCommand(compileCommand("C")); // 2.5.20 Position auslesen
        break;
    }

    switch(keyCode) {
    case DOWN:
        println();
        print("### reset EEPROM … ");
        sendCommand(compileCommand(MOTOR_CMD_EEPROM_RESET));
        delay(2000);
        println("DONE");
        break;
    }
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
*/
