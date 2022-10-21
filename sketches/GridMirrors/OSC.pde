



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
    if (a < 0) a += TWO_PI;
    return a;
  }

  void update() {
    for (int i = 0; i < 12; i++) {

      OscMessage msg = new OscMessage("/motor/position");
      float a = degrees(constellation.mMirrors[i].get_rotation() + constellation.mMirrors[i].get_rotation_offset());
      a = a % 360;
      a = mapAngle(a);
      a = (360 - a) % 360;
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

    if (msg.checkAddrPattern("/mirror/offset")) {
      /* check if the typetag is the right one. */
      if (msg.checkTypetag("if")) {
        int id = msg.get(0).intValue();
        float angle = msg.get(1).floatValue();
        Mirror m = constellation.getMirrorById(id);
        m.set_rotation_offset(radians(angle));
      }
    } else if (msg.checkAddrPattern("/mirror/rotation/angle")) {
      if (msg.checkTypetag("if")) {
        int id = msg.get(0).intValue();
        float angle = msg.get(1).floatValue();
        Mirror m = constellation.getMirrorById(id);
        m.set_rotation(radians(angle));
      }
    } else if (msg.checkAddrPattern("/mirror/reflect/enable")) {
      if (msg.checkTypetag("if")) {
        int id = msg.get(0).intValue();
        float angle = msg.get(1).floatValue();
        Mirror m = constellation.getMirrorById(id);
        m.setReflectionSourceFromAngle(radians(angle));
      }
    } else {
      System.out.println(msg);
    }
  }
}
