import teilchen.util.Intersection;
import teilchen.util.Util;

final Triangle mTriangle = new Triangle();

final Ray mRay = new Ray();

final PVector mReflectedRay = new PVector();

final PVector mIntersectionPoint = new PVector();

final boolean IGNORE_CULLING = false;

void settings() {
    size(1024, 768, P3D);
}

void setup() {
    mRay.origin.set(width / 2.0f, height / 2.0f);
    resetTriangle2D(new PVector(100, 300), new PVector(300, 100));
}

void draw() {
    background(255);
    /* compute ray from mouse pointer */
    PVector mMousePointer = new PVector(mouseX, mouseY);
    PVector.sub(mMousePointer, mRay.origin, mRay.direction);
    /* find intersection */
    final boolean mSuccess = Intersection.intersectRayTriangle(mRay.origin,
                                                               mRay.direction,
                                                               mTriangle.p0,
                                                               mTriangle.p1,
                                                               mTriangle.p2,
                                                               mIntersectionPoint);
    noFill();
    stroke(0);
    draw_triangle(mTriangle);
    line_to(mRay.origin, mRay.direction);
    if (mSuccess) {
        PVector mTempRay = new PVector(mRay.direction.x, mRay.direction.y, mRay.direction.z).normalize();
        PVector mTempNormal = new PVector(mTriangle.normal.x, mTriangle.normal.y, mTriangle.normal.z).normalize();
        float mDot = PVector.dot(mTempRay, mTempNormal);
        boolean mForwardFacing = mDot < 0.0f || IGNORE_CULLING;
        if (mForwardFacing) {
            separateComponents(mRay.direction, mTriangle.normal, mReflectedRay);
            /* draw reflected ray */
            noFill();
            stroke(0, 0, 255);
            line_to(mIntersectionPoint, mReflectedRay);
            /* draw ray beyond ray vector */
            stroke(255, 0, 0);
            line(mMousePointer, mIntersectionPoint);
            /* draw intersection point */
            fill(0);
            noStroke();
            circle(mIntersectionPoint.x, mIntersectionPoint.y, 10);
        }
    }
}

void keyPressed() {
    resetTriangle2D(new PVector(random(width), random(height)), new PVector(random(width), random(height)));
}

void resetTriangle2D(PVector p0, PVector p1) {
    mTriangle.p0.set(p0.x, p0.y);
    mTriangle.p1.set(p1.x, p1.y);
    mTriangle.p2.set(p1.x, p1.y, -1); /* a triangle is not valid if 2 points are in the exact same position */
    Util.calculateNormal(mTriangle.p0, mTriangle.p1, mTriangle.p2, mTriangle.normal);
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

void draw_triangle(Triangle pTriangle) {
    line(pTriangle.p0, pTriangle.p1);
    line(pTriangle.p1, pTriangle.p2);
    line(pTriangle.p2, pTriangle.p0);
    PVector mMidPoint = PVector.add(pTriangle.p0, pTriangle.p1).mult(0.5f);
    line_to(mMidPoint, PVector.mult(mTriangle.normal, 10));
}

void line(PVector a, PVector b) {
    line(a.x, a.y, b.x, b.y);
}

void line_to(PVector a, PVector b) {
    line(a.x, a.y, a.x + b.x, a.y + b.y);
}

static class Triangle {
    
final PVector normal = new PVector();
    
final PVector p0 = new PVector();
    
final PVector p1 = new PVector();
    
final PVector p2 = new PVector();
}

static class Ray {
    
final PVector origin = new PVector();
    
final PVector direction = new PVector();
}
