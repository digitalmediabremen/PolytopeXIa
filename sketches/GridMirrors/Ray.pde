static class Ray implements Renderable {
  final PVector origin = new PVector();
  final PVector direction = new PVector();
  final Constellation pConstellation;
  
  Ray(Constellation c) {
     pConstellation = c;
  }

  void draw(RenderContext rc) {
    //return;
    rc.g().noFill();
    rc.g().stroke(255,0,0);
    line_to(rc.g(), origin, direction);
    castRay(rc.g(), this);
  }

  void line(PGraphics g, PVector a, PVector b) {
    g.line(a.x, a.y, b.x, b.y);
  }

  void line_to(PGraphics g, PVector a, PVector b) {
    g.line(a.x, a.y, a.x + b.x, a.y + b.y);
  }

  void castRay(PGraphics g, Ray pRay) {
    /* reflect and draw ray */
    final Ray mRay = new Ray(pConstellation);
    mRay.origin.set(pRay.origin);
    mRay.direction.set(pRay.direction);
    final PVector mPreviousRayOrigin = new PVector();
    mPreviousRayOrigin.set(mRay.origin);
    int depthCounter = 0;
    while (pConstellation.reflect(mRay.origin, mRay.direction) && depthCounter < 15) {
      g.noFill();
      g.stroke(255, 0, 0);
      this.line(g, mRay.origin, mPreviousRayOrigin);
      g.fill(255, 0, 0);
      g.noStroke();
      g.circle(mRay.origin.x, mRay.origin.y, 6);
      /* store previous ray origin */
      mPreviousRayOrigin.set(mRay.origin);
      depthCounter++;
    }
    g.stroke(255,0,0);
    line_to(g, mPreviousRayOrigin, PVector.mult(mRay.direction, 100));
  }

  void set_position(PVector pPosition) {
    origin.set(pPosition);
  }

  PVector get_position() {
    return origin;
  }
}
