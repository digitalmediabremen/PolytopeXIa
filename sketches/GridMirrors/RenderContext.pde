static class RenderContext {
  private float vw, vh, vmax, vmin;
  private int w, h;
  private PGraphics g;

  public RenderContext(final PGraphics g, final int w, final int h) {
    this.g = g;
    this.w = w;
    this.h = h;
    update(w, h);
  }

  public void update(final int w, final int h) {
    this.w = w;
    this.h = h;
    vw = w / 100f;
    vh = h / 100f;
    vmax = max(vw, vh);
    vmin = min(vw, vh);
  }

  public int w() {
    return w;
  }
  
  public int h() {
    return h;
  }


  public float vw() {
    return vw;
  }

  public float vh() {
    return vh;
  }

  public float vmin() {
    return vmin;
  }

  public float vmax() {
    return vmax;
  }

  public PGraphics g() {
    return g;
  }
}
