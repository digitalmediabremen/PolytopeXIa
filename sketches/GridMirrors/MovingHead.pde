
final static int num_rays = 1;
class MovingHead implements Rotatable {
  final PVector mPosition;
  float mRotation;
  float mRotationSpeed;
  float mRotationOffset = PI;
  float mTiltOffset = 0;
  final ArrayList<Ray> mRays;

  MovingHead(Constellation c) {
    mPosition = new PVector();
    mRotation = 0.0f;
    mRotationSpeed = 0.0f;
    mRays = new ArrayList();
    initRays(c);
  }

  private void initRays(Constellation c) {
    for (int i = 0; i < num_rays; i++) {
      Ray ray = new Ray(c);
      ray.origin.set(mPosition);
      mRays.add(ray);
    }
  }

  private void updateRays() {
    for (int i = 0; i < num_rays; i++) {
      final Ray ray = mRays.get(i);
      float direction_offset = map(i, 0, num_rays, radians(-0.3f), radians(0.3f));
      direction_offset = 0;
      ray.origin.set(mPosition);
      ray.direction.set(sin(get_rotation() + direction_offset + HALF_PI), cos(get_rotation() + direction_offset + HALF_PI)).mult(20);
    }
  }

  void set_rotation(float pRotation) {
    mRotation = pRotation;
    updateRays();
  }

  float get_rotation() {
    return mRotation;
  }

  void set_tilt_offset(float pTiltOffset) {
    mTiltOffset = pTiltOffset;
  }

  void set_rotation_offset(float pRotationOffset) {
    mRotationOffset = pRotationOffset;
    updateRays();
  }

  float get_rotation_offset() {
    return mRotationOffset;
  }

  float get_tilt_offset() {
    return mTiltOffset;
  }

  float angle(PVector v1, PVector v2) {
    float a = atan2(v2.y, v2.x) - atan2(v1.y, v1.x);
    if (a < 0) a += TWO_PI;
    return a;
  }


  void update(float pDelta) {
    //PVector mouse = new PVector(mouseX, mouseY);
    //PVector direction = PVector.sub(this.get_position(), mouse);
    //float heading = angle(direction, PVector.fromAngle(PI));
    //mRotation = heading;
    //updateRays();
    //if (mRotationSpeed != 0) {
    //  mRotation += mRotationSpeed * pDelta;
    //  updateRays();
    //}
  }

  void set_rotation_speed(float pRotationSpeed) {
    mRotationSpeed = pRotationSpeed;
  }

  void draw(RenderContext rc) {
    final PGraphics g = rc.g();
    final PVector d = new PVector(sin(get_rotation() + HALF_PI), cos(get_rotation() + HALF_PI));
    final PVector p = PVector.mult(d, 20 * 0.5f).add(mPosition);
    g.pushMatrix();

    g.stroke(0);
    g.noFill();
    g.translate(mPosition.x, mPosition.y);
    g.stroke(0, 180, 0);
    g.fill(0, 180, 0, 20);
    g.circle(0, 0, 4 * rc.vw());
    g.stroke(0);
    g.noFill();
    g.rotate(-get_rotation());
    g.rect(0 - rc.vw(), 0 - .5f * rc.vw(), 2 * rc.vw(), rc.vw());
    g.popMatrix();
    //g.line(mPosition.x, mPosition.y, p.x, p.y);
  }

  void set_position(PVector pPosition) {
    mPosition.set(pPosition);
    updateRays();
  }

  PVector get_position() {
    return mPosition;
  }
}
