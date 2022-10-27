import processing.serial.*;

import static processing.core.PApplet.match;
import static processing.core.PApplet.matchAll;
import static processing.core.PApplet.parseInt;
import static processing.core.PApplet.println;
import static processing.core.PApplet.printArray;

import processing.core.PApplet;


public class CommandController {
  public static class Command {
    final int COMMAND_TIMEOUT = 10;
    boolean blocking = true;
    int motorId;
    String command;
    int value;
    boolean hasValue;
    long commandSentAt;


    public Command(int motorId, String command, int value) {
      this.motorId = motorId;
      this.command = command;
      this.value = value;
      this.hasValue = true;
      this.commandSentAt = currentTime();
    }

    public Command(int motorId, String command) {
      this.motorId = motorId;
      this.command = command;
      this.hasValue = false;
      this.commandSentAt = currentTime();
    }

    public boolean timedOut() {
      return (this.currentTime() - this.commandSentAt) > this.COMMAND_TIMEOUT;
    }

    public void updateTime() {
      this.commandSentAt = currentTime();
    }

    boolean matches(Response response) {
      if (motorId != response.motorId) return false;
      if (!command.equals(response.command)) return false;
      if (hasValue && value != response.value) return false;
      return true;
    }

    private long currentTime() {
      return System.currentTimeMillis();
    }

    public String toString() {
      String c = "#"+ (motorId == 0 ? "*" : motorId) + command;
      if (hasValue) {
        c += value;
      }
      c += "\r";
      return c;
    }
  }

  public static class ResponseParseException extends Exception {
    public ResponseParseException(String responseString) {
      super("Response string failed to parse, " + responseString);
    }
  }

  public static class CommandTimedOutException extends Exception {
    public CommandTimedOutException(Command command) {
      super("Command timed out, " + command);
    }
  }

  public static class Response {
    int motorId;
    String command;
    int value;
    boolean hasValue;

    public Response(int motorId, String command, int value) {
      this.motorId = motorId;
      this.command = command;
      this.value = value;
      this.hasValue = true;
    }

    public Response(int motorId, String command) {
      this.motorId = motorId;
      this.command = command;
      this.hasValue = false;
    }

    public static Response parse(String commandString) throws ResponseParseException {
      String[] matches = match(commandString, "(\\d{1,2}|\\*)([A-Za-z]|:[A-Za-z_]+)([0-9+-.]+)?");
      if (matches == null) throw new ResponseParseException(commandString);
      int id = parseInt(matches[1]);
      String c = matches[2];
      int v = 0;
      boolean hasValue = false;
      if (matches[3] != null) {
        v = parseInt(matches[3]);
        hasValue = true;
      }

      if (hasValue) {
        return new Response(id, c, v);
      } else {
        return new Response(id, c);
      }
    }

    public String toString() {
      String c = (motorId == 0 ? "*" : motorId) + command;
      if (hasValue) {
        c += value;
      }
      c += "\r";
      return c;
    }
  }
  private final int RETRY_COUNT = 3;
  private final Serial MOTOR_SERIAL;
  MotorController mc;
  Response commandResponse;

  public CommandController(PApplet instance, MotorController mc, String serialPortName) {
    MOTOR_SERIAL = new Serial(instance, serialPortName, 115200);
    MOTOR_SERIAL.bufferUntil('\r');
    this.mc = mc;
  }

  public int sendCommand(String commandString)  throws CommandTimedOutException {
    commandResponse = null;
    Command command = new Command(0, commandString);
    return sendCommand(command, RETRY_COUNT).value;
  }

  public int sendCommand(int motorId, String commandString)  throws CommandTimedOutException {
    commandResponse = null;
    Command command = new Command(motorId, commandString);
    return sendCommand(command, RETRY_COUNT).value;
  }

  public int sendCommand(int motorId, String commandString, int value) throws CommandTimedOutException {
    commandResponse = null;
    Command command = new Command(motorId, commandString, value);
    return sendCommand(command, RETRY_COUNT).value;
  }

  public Response sendCommand(Command command, int retry) throws CommandTimedOutException {
    commandResponse = null;
    MOTOR_SERIAL.write(command.toString());
    while (true) {
      if (command.timedOut()) {
        if (retry == 0) {
          throw new CommandTimedOutException(command);
        } else {
          command.updateTime();
          return sendCommand(command, retry - 1);
        }
      } else if (commandResponse != null && command.matches(this.commandResponse)) {
        Response r = this.commandResponse;
        this.commandResponse = null;
        return r;
      } else if (commandResponse != null) {
        println("didnt match", command, commandResponse);
      }
      mc.delay(1);
    }
  }

  public static void listSerialDevices() {
    printArray(Serial.list());
  }

  public void serialEvent(Serial MOTOR_SERIAL) {
    String inBuffer = MOTOR_SERIAL.readString();
    if (inBuffer != null) {
      try {
        this.commandResponse = Response.parse(inBuffer);
      }
      catch (Exception e) {
        println(e);
      }
    }
  }
}
