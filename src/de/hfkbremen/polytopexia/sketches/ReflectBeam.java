package de.hfkbremen.polytopexia.sketches;

import processing.core.PApplet;
import processing.core.PVector;
import teilchen.util.Intersection;
import teilchen.util.Util;

public class ReflectBeam extends PApplet {
    private final Triangle mTriangle = new Triangle();
    private final Ray mRay = new Ray();
    private final PVector mReflectedRay = new PVector();
    private final PVector mIntersectionPoint = new PVector();
    private final boolean IGNORE_CULLING = false;

    public void settings() {
        size(1024, 768, P3D);
    }

    public void setup() {
        mRay.origin.set(width / 2.0f, height / 2.0f);
        resetTriangle2D(new PVector(100, 300), new PVector(300, 100));
    }

    public void draw() {
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
            PVector mTempRay = new PVector().set(mRay.direction).normalize();
            PVector mTempNormal = new PVector().set(mTriangle.normal).normalize();
            float mDot = PVector.dot(mTempRay, mTempNormal);
            boolean mForwardFacing = mDot < 0.0f || IGNORE_CULLING;
            if (mForwardFacing) {
                separateComponents(mRay.direction, mTriangle.normal, mReflectedRay);

                /* see if ray passed plane */
                final float mIntersectLength = PVector.sub(mIntersectionPoint, mRay.origin).magSq();
                final float mRayLength = mRay.direction.magSq();

                if (mIntersectLength < mRayLength) {
                    /* draw reflected ray */
                    noFill();
                    stroke(0, 0, 255);
                    line_to(mIntersectionPoint, mReflectedRay);
                }

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

    public void keyPressed() {
        resetTriangle2D(new PVector(random(width), random(height)), new PVector(random(width), random(height)));
    }

    private void resetTriangle2D(PVector p0, PVector p1) {
        mTriangle.p0.set(p0.x, p0.y);
        mTriangle.p1.set(p1.x, p1.y);
        mTriangle.p2.set(p1.x, p1.y, -1); /* a triangle is not valid if 2 points are in the exact same position */
        Util.calculateNormal(mTriangle.p0, mTriangle.p1, mTriangle.p2, mTriangle.normal);
    }

    private void separateComponents(PVector pIncidentAngle, PVector pNormal, PVector pReflectionVector) {
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

    private void draw_triangle(Triangle pTriangle) {
        line(pTriangle.p0, pTriangle.p1);
        line(pTriangle.p1, pTriangle.p2);
        line(pTriangle.p2, pTriangle.p0);
        PVector mMidPoint = PVector.add(pTriangle.p0, pTriangle.p1).mult(0.5f);
        line_to(mMidPoint, PVector.mult(mTriangle.normal, 10));
    }

    private void line(PVector a, PVector b) {
        line(a.x, a.y, b.x, b.y);
    }

    private void line_to(PVector a, PVector b) {
        line(a.x, a.y, a.x + b.x, a.y + b.y);
    }

    private static class Triangle {
        private final PVector normal = new PVector();
        private final PVector p0 = new PVector();
        private final PVector p1 = new PVector();
        private final PVector p2 = new PVector();
    }

    private static class Ray {
        private final PVector origin = new PVector();
        private final PVector direction = new PVector();
    }

    public static void main(String[] args) {
        PApplet.main(ReflectBeam.class.getName());
    }
}