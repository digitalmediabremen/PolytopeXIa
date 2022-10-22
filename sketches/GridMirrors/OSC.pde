



static class OSCController {
  OscP5 oscP5;
  Constellation constellation;
  NetAddress myRemoteLocation = new NetAddress("127.0.0.1", 8000);
  float[] old = new float[12];


  public OSCController(Constellation c) {
    oscP5 = new OscP5(this, 8001);
    constellation = c;
  }


  float mapAngle(float a) {
    if (a < -360) a += 360;
    if (a > 360) a -= 360;
    return a;
  }

  void update() {
    for (int i = 0; i < 12; i++) {

      OscMessage msg = new OscMessage("/motor/position");
      float a = degrees(constellation.mMirrors[i].get_rotation() + constellation.mMirrors[i].get_rotation_offset());
      a = mapAngle(a * -1);
      if (a != old[i]) {
        msg.add(i+1);
        msg.add(a);
        oscP5.send(msg, myRemoteLocation);
        old[i] = a;
      }
      //prin tln(msg);
    }
  }

  void oscEvent(OscMessage msg) {
    /* check if theOscMessage has the address pattern we are looking for. */

    if (msg.checkAddrPattern("/composition")) {
      /* check if the typetag is the right one. */
      if (msg.checkTypetag("s")) {
        String compositionString = msg.get(0).stringValue();
        constellation.loadConstellation(compositionString);
      }
    }
  }
}
