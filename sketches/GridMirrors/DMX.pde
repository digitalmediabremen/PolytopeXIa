
import java.lang.reflect.Proxy;
import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Method;

static class DMXHandler implements InvocationHandler {
  Object invoke(Object proxy,
    Method method,
    Object[] args)
    throws Throwable {
    println(method.getName());
    if (method.getName() == "pan") {
      float f = (float)args[0];
      println(f);
      return 4;
    }
    return new Object();
  }
}

static class DMXController {
  byte[] dmxData = new byte[512];
  ArtNetClient artnet;
  Constellation constellation;
  InvocationHandler handler = new DMXHandler();
  final int[] DMX_PAN_CHANNELS = {200, 250, 300, 350};
  final int[] DMX_TILT_CHANNELS = {202, 252, 302, 352};

  public DMXController (Constellation c) {
    artnet = new ArtNetClient(null);
    constellation = c;
    artnet.start();
    //Cobra cobra = create(Cobra.class);
    //cobra.
  }

  byte[] toDmxValue(float v, float range) {
    float q = v % range;
    if (q < 0) q = range + q;
    q = (range - q) % range;
    int i = (int) ((q / range) * (255 * 255));
    byte lower = (byte) (i / 255);
    byte higher = (byte)(i % 255);
    return new byte[]{lower, higher};
  }

  void update() {
    for (int i = 0; i < 4; i++) {
      float rotation = constellation.mLights[i].get_rotation();
      float rotation_offset = constellation.mLights[i].get_rotation_offset();
      byte[] pan_bytes = toDmxValue(degrees(rotation+rotation_offset) + 180, 540);
          //println("L" + (i+1), pan_bytes[0], pan_bytes[1]);

      dmxData[DMX_PAN_CHANNELS[i]] = pan_bytes[0];
      dmxData[DMX_PAN_CHANNELS[i] + 1] = pan_bytes[1];
      byte[] tilt_bytes = toDmxValue(45 + degrees(constellation.mLights[i].get_tilt_offset()), 270);
      dmxData[DMX_TILT_CHANNELS[i]] = tilt_bytes[0];
      dmxData[DMX_TILT_CHANNELS[i] + 1] = tilt_bytes[1];
    }
    artnet.unicastDmx("10.0.100.6", 0, 12, dmxData);
  }

  <T> T create(Class<T> _class) {
    T f = (T) Proxy.newProxyInstance(_class.getClassLoader(),
      new Class[] { _class },
      handler);
    return f;
  }

  interface Cobra {
    /**
     * This method fromulgates the wibble-wrangler. It should not be called without
     * first saturating all glashnashers.
     * @param  number  an absolute URL giving the base location of the image
     */
    void pan(float number);
  }
}
