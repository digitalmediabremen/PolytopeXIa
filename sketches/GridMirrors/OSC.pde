



static class OSCController {
  OscP5 oscP5;
  Constellation constellation;
  public OSCController(Constellation c) {
    oscP5 = new OscP5(this, "localhost", 8000);
    constellation = c;
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
