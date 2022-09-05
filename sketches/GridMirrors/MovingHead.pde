final static int num_rays = 12;
class MovingHead implements Rotatable {
  final PVector mPosition;
  float mRotation;
  float mRotationSpeed;
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
      final float direction_offset = map(i, 0, num_rays, radians(-0.3f), radians(0.3f)); 
      ray.origin.set(mPosition);
      ray.direction.set(sin(mRotation + direction_offset + HALF_PI), cos(mRotation + direction_offset + HALF_PI)).mult(20);
    }
  }
  
  void set_rotation(float pRotation) {
    mRotation = pRotation;
    updateRays();
  }

  float get_rotation() {
    return mRotation;
  }

  void update(float pDelta) {
    if (mRotationSpeed != 0) {
      mRotation += mRotationSpeed * pDelta;
      updateRays();
    }
  }

  void set_rotation_speed(float pRotationSpeed) {
    mRotationSpeed = pRotationSpeed;
  }

  void draw(PGraphics g) {
    final PVector d = new PVector(sin(mRotation + HALF_PI), cos(mRotation + HALF_PI));
    final PVector p = PVector.mult(d, 20 * 0.5f).add(mPosition);
    g.pushMatrix();
 
    g.stroke(0);
    g.noFill();
    g.translate(mPosition.x, mPosition.y);
    g.stroke(0,180,0);
    g.fill(0,180,0,20);
    g.circle(0,0,4 * vw);
    g.stroke(0);
    g.noFill();
    g.rotate(-mRotation);
    g.rect(0 - vw, 0 - .5f * vw, 2 * vw, vw);
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
