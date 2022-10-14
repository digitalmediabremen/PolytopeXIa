interface Renderable {
  public void draw(RenderContext rc);
  public PVector get_position();
  public void set_position(PVector position);
}

interface Rotatable extends Renderable {
  void set_rotation(float pRotation);
  float get_rotation();
  void set_rotation_speed(float pRotationSpeed);
  void update(float pDelta);
}


static class Triangle {
  final PVector normal = new PVector();
  final PVector p0 = new PVector();
  final PVector p1 = new PVector();
  final PVector p2 = new PVector();
}

static class Pole implements Renderable {
  final PVector mPosition;
  final boolean mBlocked;

  Pole(boolean blocked) {
    mPosition = new PVector();
    mBlocked = blocked;
  }

  void draw(RenderContext rc) {
    //g.rect(mPosition.x - 5, mPosition.y- 5, 10,10);
    if (mBlocked) rc.g().fill(100, 100, 100);
    else rc.g().fill(200, 200, 200);
    rc.g().noStroke();
    rc.g().rect(mPosition.x - .5f * rc.vw(), mPosition.y - .5f * rc.vw(), 1 * rc.vw(), 1 * rc.vw());
  }

  void set_position(PVector pPosition) {
    mPosition.set(pPosition);
  }

  PVector get_position() {
    return mPosition;
  }
}

class Mirror implements Renderable, Rotatable {
  final Triangle mTriangleA;
  final Triangle mTriangleB;
  final PVector mIntersectionPoint;
  final PVector mReflectedRay;
  final PVector mPosition;
  float mRotation;
  float mWidth;
  float mRotationSpeed;
  boolean mBothSidesReflect = true;
  PVector mIncomingRayDirection;

  Mirror() {
    mPosition = new PVector();
    mReflectedRay = new PVector();
    mRotation = 0.0f;
    mRotationSpeed = 0.0f;
    mWidth = 5.0f;
    mTriangleA = new Triangle();
    mTriangleB = new Triangle();
    mIntersectionPoint = new PVector();
  }

  void draw(RenderContext rc) {
    final PGraphics g = rc.g();
    g.fill(255, 0, 255, 100);
    g.noStroke();

    g.rect(mPosition.x - 1f * rc.vw(), mPosition.y - 1f * rc.vw(), 2 * rc.vw(), 2 * rc.vw());
    if (mIncomingRayDirection != null) {
      g.line(mPosition.x, mPosition.y, mPosition.x + mIncomingRayDirection.x * rc.vw() * 4, mPosition.y + mIncomingRayDirection.y * rc.vw() * 4);
    }
    draw_triangle(g, mTriangleA);
    draw_triangle(g, mTriangleB);
  }

  PVector intersection_point() {
    return mIntersectionPoint;
  }

  PVector reflected_ray() {
    return mReflectedRay;
  }

  void set_both_sides_reflect(boolean pBothSidesReflect) {
    mBothSidesReflect = pBothSidesReflect;
  }

  boolean reflect(Ray mRay) {
    boolean mSuccess;
    PVector mNormal = null;
    /* triangle a */
    mSuccess = teilchen.util.Intersection.intersectRayTriangle(mRay.origin,
      mRay.direction,
      mTriangleA.p0,
      mTriangleA.p1,
      mTriangleA.p2,
      mIntersectionPoint);
    mNormal = mTriangleA.normal;
    /* triangle b -- test both triangles */
    if (!mSuccess) {
      mSuccess = teilchen.util.Intersection.intersectRayTriangle(mRay.origin,
        mRay.direction,
        mTriangleB.p0,
        mTriangleB.p1,
        mTriangleB.p2,
        mIntersectionPoint);
      mNormal = mTriangleB.normal;
    }
    if (mSuccess) {
      PVector mTempRay = new PVector().set(mRay.direction).normalize();
      PVector mTempNormal = new PVector().set(mNormal).normalize();
      float mDot = PVector.dot(mTempRay, mTempNormal);
      boolean mForwardFacing = mDot < 0.0f || mBothSidesReflect;
      if (mForwardFacing) {
        separateComponents(mRay.direction, mNormal, mReflectedRay);
        return true;
      }
    }
    return false;
  }

  void set_position(PVector pPosition) {
    mPosition.set(pPosition);
    update_triangles();
  }

  PVector get_position() {
    return mPosition;
  }

  void set_width(float pWidth) {
    mWidth = pWidth;
    update_triangles();
  }

  void set_rotation(float pRotation) {
    mRotation = pRotation;
    update_triangles();
  }

  float get_rotation() {
    return mRotation;
  }

  float get_width() {
    return mWidth;
  }


  float angle(PVector v1, PVector v2) {
    float a = atan2(v2.y, v2.x) - atan2(v1.y, v1.x);
    if (a < 0) a += TWO_PI;
    return a;
  }

  void update(float pDelta) {
    if (mIncomingRayDirection != null) {
      float incoming = angle(mIncomingRayDirection, PVector.fromAngle(PI));

      float outgoing = angle(PVector.sub(new PVector(mouseX, mouseY), mPosition), mIncomingRayDirection);

      mRotation = incoming + outgoing * 0.5;
    }
    //mRotation = angle(PVector.cross(PVector.sub(mPosition, new PVector(mouseX, mouseY)), mIncomingRayDirection), PVector.fromAngle(PI));
    update_triangles();
    //if (mRotationSpeed != 0) {
    //  mRotation += mRotationSpeed * pDelta;
    //  update_triangles();
    //}
  }

  void set_rotation_speed(float pRotationSpeed) {
    mRotationSpeed = pRotationSpeed;
  }

  void update_triangles() {
    PVector d = new PVector(sin(mRotation), cos(mRotation));
    PVector.mult(d, mWidth * 0.5f, mTriangleA.p0).add(mPosition);
    PVector.mult(d, mWidth * -0.5f, mTriangleA.p1).add(mPosition);
    /* update 2nd triangle */
    mTriangleB.p0.set(mTriangleA.p0);
    mTriangleB.p1.set(mTriangleA.p1);
    /* a triangle is not valid if 2 points are in the exact same position */
    mTriangleA.p2.set(mTriangleA.p1.x, mTriangleA.p1.y, -10);
    mTriangleB.p2.set(mTriangleB.p0.x, mTriangleB.p0.y, -10);
    teilchen.util.Util.calculateNormal(mTriangleA.p0, mTriangleA.p1, mTriangleA.p2, mTriangleA.normal);
    teilchen.util.Util.calculateNormal(mTriangleB.p0, mTriangleB.p1, mTriangleB.p2, mTriangleB.normal);
  }

  void separateComponents(PVector pIncidentAngle, PVector pNormal, PVector pReflectionVector) {
    final PVector mTempNormalComponent = new PVector();
    final PVector mTempTangentComponent = new PVector();
    /* normal */
    mTempNormalComponent.set(pNormal);
    mTempNormalComponent.mult(pNormal.dot(pIncidentAngle));
    /* tangent */
    PVector.sub(pIncidentAngle, mTempNormalComponent, mTempTangentComponent);
    /* negate normal */
    mTempNormalComponent.mult(-1.0f);
    /* set reflection vector */
    PVector.add(mTempTangentComponent, mTempNormalComponent, pReflectionVector);
  }

  void draw_triangle(PGraphics g, Triangle pTriangle) {
    g.pushStyle();
    PVector mMidPoint = PVector.add(pTriangle.p0, pTriangle.p1).mult(0.5f);
    line_to(g, mMidPoint, PVector.mult(pTriangle.normal, 10));
    line(g, pTriangle.p0, pTriangle.p1);
    line(g, pTriangle.p1, pTriangle.p2);
    line(g, pTriangle.p2, pTriangle.p0);
    g.popStyle();
  }

  void line(PGraphics g, PVector a, PVector b) {
    g.stroke(0);
    g.strokeWeight(2);
    g.line(a.x, a.y, b.x, b.y);
  }

  void line_to(PGraphics g, PVector a, PVector b) {
    g.stroke(200);
    g.strokeWeight(1);
    g.line(a.x, a.y, a.x + b.x, a.y + b.y);
  }
}
