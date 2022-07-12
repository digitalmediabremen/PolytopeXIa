package de.hfkbremen.polytopexia.sketches;

import processing.core.PApplet;
import processing.core.PGraphics;
import processing.core.PVector;
import teilchen.util.Intersection;
import teilchen.util.Util;

import java.util.ArrayList;

public class GridMirrors extends PApplet {

    private Ray mRay;
    private ArrayList<Mirror> mMirrors;

    public void settings() {
        size(1024, 768, P3D);
    }

    public void setup() {
        mRay = new Ray();

        mMirrors = new ArrayList<>();
        for (int i = 0; i < 24; i++) {
            final int x = i % 6;
            final int y = i / 6;
            println(x + "," + y);
            final float mPitchWidth = width / 7.0f;
            final float mPitchHeight = height / 5.0f;
            Mirror mMirror = new Mirror();
            mMirror.set_position(new PVector(x * mPitchWidth + mPitchWidth, y * mPitchHeight + mPitchHeight));
            mMirror.set_rotation(random(TWO_PI));
            mMirrors.add(mMirror);
        }
    }

    public void draw() {
        background(255);

        noFill();
        stroke(0);

        for (Mirror mMirror : mMirrors) {
            mMirror.draw(g);
//            mMirror.set_rotation(mMirror.get_rotation() + TWO_PI * 0.001f);
        }

        mRay.origin.set(width / 2.0f, height / 2.0f);
        PVector mMousePointer = new PVector(mouseX, mouseY);
        PVector.sub(mMousePointer, mRay.origin, mRay.direction);

        noFill();
        stroke(0);
        line_to(mRay.origin, mRay.direction);

        PVector mRayOrigin = new PVector();
        mRayOrigin.set(mRay.origin);
        while (reflect(mRay.origin, mRay.direction)) {
            noFill();
            stroke(255, 0, 0);
            line(mRay.origin, mRayOrigin);
            mRayOrigin.set(mRay.origin);
        }
        stroke(0);
        line_to(mRayOrigin, mRay.direction);
    }

    private boolean reflect(PVector pRayOrigin, PVector pRayDirection) {
        for (Mirror mMirror : mMirrors) {
            Ray mRay = new Ray();
            mRay.origin.set(pRayOrigin);
            mRay.direction.set(pRayDirection);
            PVector mReflection = mMirror.reflect(mRay);

            if (mReflection != null) {
//                noFill();
//                stroke(255, 0, 0);
//                line(mRay.origin, mMirror.intersection_point());
                //                line_to(mMirror.intersection_point(), mReflection);
                fill(255, 0, 0);
                noStroke();
                circle(mMirror.intersection_point().x, mMirror.intersection_point().y, 10);

                pRayOrigin.set(mMirror.intersection_point());
                pRayDirection.set(mReflection);
                return true;
//            } else {
//                line_to(mRay.origin, mRay.direction);
            }
        }
        return false;
    }

    public void keyPressed() {
        Mirror mMirror = mMirrors.get(0);
        mMirror.set_rotation(mMirror.get_rotation() + TWO_PI / 64.0f);
    }

    private void line(PVector a, PVector b) {
        line(a.x, a.y, b.x, b.y);
    }

    private void line_to(PVector a, PVector b) {
        line(a.x, a.y, a.x + b.x, a.y + b.y);
    }

    private static class Mirror {

        private final Triangle mTriangle;
        private final PVector mIntersectionPoint;
        private final PVector mReflectedRay = new PVector();
        private final PVector mPosition;
        private float mRotation;
        private float mWidth;
        private boolean mBothSidesReflect = true;

        public Mirror() {
            mPosition = new PVector();
            mRotation = 0.0f;
            mWidth = 50.0f;
            mTriangle = new Triangle();
            mIntersectionPoint = new PVector();
        }

        public void draw(PGraphics g) {
            draw_triangle(g, mTriangle);
        }

        public PVector intersection_point() {
            return mIntersectionPoint;
        }

        public void set_both_sides_reflect(boolean pBothSidesReflect) {
            mBothSidesReflect = pBothSidesReflect;
        }

        public PVector reflect(Ray mRay) {
            final boolean mSuccess = Intersection.intersectRayTriangle(mRay.origin, mRay.direction, mTriangle.p0,
                                                                       mTriangle.p1, mTriangle.p2, mIntersectionPoint);
            if (mSuccess) {
                PVector mTempRay = new PVector().set(mRay.direction).normalize();
                PVector mTempNormal = new PVector().set(mTriangle.normal).normalize();
                float mDot = PVector.dot(mTempRay, mTempNormal);
                boolean mForwardFacing = mDot < 0.0f || mBothSidesReflect;
                if (mForwardFacing) {
                    separateComponents(mRay.direction, mTriangle.normal, mReflectedRay);
                    return mReflectedRay;
                }
            }
            return null;
        }

        public void set_position(PVector pPosition) {
            mPosition.set(pPosition);
            update();
        }

        public void set_width(float pWidth) {
            mWidth = pWidth;
            update();
        }

        public void set_rotation(float pRotation) {
            mRotation = pRotation;
            update();
        }

        public float get_rotation() {
            return mRotation;
        }

        private void update() {
            PVector d = new PVector(sin(mRotation), cos(mRotation));
            PVector.mult(d, mWidth * 0.5f, mTriangle.p0).add(mPosition);
            PVector.mult(d, mWidth * -0.5f, mTriangle.p1).add(mPosition);
            mTriangle.p2.set(mTriangle.p1.x, mTriangle.p1.y, -10);
            /* a triangle is not valid if 2 points are in the exact same position */
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

        private void draw_triangle(PGraphics g, Triangle pTriangle) {
            line(g, pTriangle.p0, pTriangle.p1);
            line(g, pTriangle.p1, pTriangle.p2);
            line(g, pTriangle.p2, pTriangle.p0);
            PVector mMidPoint = PVector.add(pTriangle.p0, pTriangle.p1).mult(0.5f);
            line_to(g, mMidPoint, PVector.mult(mTriangle.normal, 10));
        }

        private void line(PGraphics g, PVector a, PVector b) {
            g.line(a.x, a.y, b.x, b.y);
        }

        private void line_to(PGraphics g, PVector a, PVector b) {
            g.line(a.x, a.y, a.x + b.x, a.y + b.y);
        }
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
        PApplet.main(GridMirrors.class.getName());
    }
}
