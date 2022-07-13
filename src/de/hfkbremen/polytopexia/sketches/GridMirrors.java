package de.hfkbremen.polytopexia.sketches;

import processing.core.PApplet;
import processing.core.PGraphics;
import processing.core.PVector;

import java.util.ArrayList;

public class GridMirrors extends PApplet {

    private static final int GRID_X = 6;
    private static final int GRID_Y = 4;
    private static final int NUM_RAYS = 5;
    private ArrayList<Ray> mRays;
    private ArrayList<Mirror> mMirrors;
    private int mSelectedMirrorID_X;
    private int mSelectedMirrorID_Y;
    private int mSelectedRayID;

    public void settings() {
        size(1024, 768, P3D);
    }

    public void setup() {
        mSelectedMirrorID_X = 0;
        mSelectedMirrorID_Y = 0;
        mSelectedRayID = 0;
        mRays = new ArrayList<>();
        for (int i = 0; i < NUM_RAYS; i++) {
            final Ray mRay = new Ray();
            mRay.origin.set(width / 2.0f, height / 2.0f);
            mRays.add(mRay);
        }
        mMirrors = new ArrayList<>();
        for (int i = 0; i < GRID_X * GRID_Y; i++) {
            final int x = i % GRID_X;
            final int y = i / GRID_X;
            final float mPitchWidth = width / (float) (GRID_X + 1);
            final float mPitchHeight = height / (float) (GRID_Y + 1);
            Mirror mMirror = new Mirror();
            mMirror.set_position(new PVector(x * mPitchWidth + mPitchWidth, y * mPitchHeight + mPitchHeight));
            mMirror.set_rotation(random(TWO_PI));
            mMirror.set_width(50);
            mMirror.set_both_sides_reflect(true);
            mMirrors.add(mMirror);
        }
    }

    public void draw() {
        handleKeyPressed();

        /* update mirror rotation */
        for (Mirror mMirror : mMirrors) {
            mMirror.update(1.0f / frameRate);
        }

        Ray mSelectedRay = mRays.get(mSelectedRayID);
        PVector mMousePointer = new PVector(mouseX, mouseY);
        PVector.sub(mMousePointer, mSelectedRay.origin, mSelectedRay.direction);

        /* draw */
        background(255);

        /* draw mirrors */
        noFill();
        stroke(0);
        for (Mirror mMirror : mMirrors) {
            mMirror.draw(g);
        }

        /* highlight selected mirror */
        final int mSelectedMirrorID = mSelectedMirrorID_X + mSelectedMirrorID_Y * GRID_X;
        final Mirror mSelectedMirror = mMirrors.get(mSelectedMirrorID);
        PVector mSelectedMirrorPosition = mSelectedMirror.get_position();
        noFill();
        stroke(0);
        circle(mSelectedMirrorPosition.x, mSelectedMirrorPosition.y, mSelectedMirror.get_width() + 8);

        for (Ray mRay : mRays) {
            /* draw initial ray */
            noFill();
            stroke(0);
            line_to(mRay.origin, mRay.direction);
            castRay(mRay);
        }
    }

    private void castRay(Ray pRay) {
        /* reflect and draw ray */
        final Ray mRay = new Ray();
        mRay.origin.set(pRay.origin);
        mRay.direction.set(pRay.direction);
        final PVector mPreviousRayOrigin = new PVector();
        mPreviousRayOrigin.set(mRay.origin);
        while (reflect(mRay.origin, mRay.direction)) {
            noFill();
            stroke(255, 0, 0);
            line(mRay.origin, mPreviousRayOrigin);
            fill(255, 0, 0);
            noStroke();
            circle(mRay.origin.x, mRay.origin.y, 6);
            /* store previous ray origin */
            mPreviousRayOrigin.set(mRay.origin);
        }
        stroke(0);
        line_to(mPreviousRayOrigin, PVector.mult(mRay.direction, 10));
    }

    private void handleKeyPressed() {
        if (keyPressed) {
            final int mSelectedMirrorID = mSelectedMirrorID_X + mSelectedMirrorID_Y * GRID_X;
            final Mirror mSelectedMirror = mMirrors.get(mSelectedMirrorID);
            final float mMirrorRotationStep = TWO_PI / (2.0f * 360.0f); // 0.5° step size
            switch (key) {
                case 'q':
                    mSelectedMirror.set_rotation(mSelectedMirror.get_rotation() + mMirrorRotationStep);
                    break;
                case 'w':
                    mSelectedMirror.set_rotation(mSelectedMirror.get_rotation() - mMirrorRotationStep);
                    break;
            }
        }
    }

    private boolean reflect(PVector pRayOrigin, PVector pRayDirection) {
        final ArrayList<Ray> mIntersections = new ArrayList<>();
        for (Mirror mMirror : mMirrors) {
            final Ray mRay = new Ray();
            mRay.origin.set(pRayOrigin);
            mRay.direction.set(pRayDirection);
            if (mMirror.reflect(mRay)) {
                mRay.origin.set(mMirror.intersection_point());
                mRay.direction.set(mMirror.reflected_ray());
                mIntersections.add(mRay);
            }
        }
        if (mIntersections.isEmpty()) {
            return false;
        } else {
            /* find nearest intersection */
            int mClosestID = -1;
            float mClosestDistance = Float.MAX_VALUE;
            final float MINIMUM_DISTANCE = 1.0f;
            for (int i = 0; i < mIntersections.size(); i++) {
                final Ray mIntersection = mIntersections.get(i);
                float mDistance = PVector.dist(mIntersection.origin, pRayOrigin);
                if (mDistance < mClosestDistance && mDistance > MINIMUM_DISTANCE) {
                    mClosestDistance = mDistance;
                    mClosestID = i;
                }
            }
            if (mClosestID == -1) {
                return false;
            }
            pRayOrigin.set(mIntersections.get(mClosestID).origin);
            pRayDirection.set(mIntersections.get(mClosestID).direction);
            return true;
        }
    }

    public void mousePressed() {
        if (mouseButton == LEFT) {
            mSelectedRayID++;
            mSelectedRayID %= NUM_RAYS;
        } else if (mouseButton == RIGHT) {
            Ray mSelectedRay = mRays.get(mSelectedRayID);
            PVector mMousePointer = new PVector(mouseX, mouseY);
            mSelectedRay.origin.set(mMousePointer);
        }
    }

    public void keyPressed() {
        switch (keyCode) {
            case LEFT:
                mSelectedMirrorID_X--;
                mSelectedMirrorID_X += GRID_X;
                mSelectedMirrorID_X %= GRID_X;
                break;
            case RIGHT:
                mSelectedMirrorID_X++;
                mSelectedMirrorID_X %= GRID_X;
                break;
            case UP:
                mSelectedMirrorID_Y--;
                mSelectedMirrorID_Y += GRID_Y;
                mSelectedMirrorID_Y %= GRID_Y;
                break;
            case DOWN:
                mSelectedMirrorID_Y++;
                mSelectedMirrorID_Y %= GRID_Y;
                break;
        }
        final int mSelectedMirrorID = mSelectedMirrorID_X + mSelectedMirrorID_Y * GRID_X;
        final Mirror mSelectedMirror = mMirrors.get(mSelectedMirrorID);
        switch (key) {
            case 'R': {
                for (Mirror mMirror : mMirrors) {
                    final int mSign = random(0, 1) > 0.5f ? 1 : -1;
                    final float mSpeed = random(PI * 0.1f, PI * 0.5f) * mSign;
                    mMirror.set_rotation_speed(mSpeed);
                }
            }
            break;
            case 'r': {
                final int mSign = random(0, 1) > 0.5f ? 1 : -1;
                final float mSpeed = random(PI * 0.1f, PI * 0.5f) * mSign;
                mSelectedMirror.set_rotation_speed(mSpeed);
            }
            break;
            case 'S':
                for (Mirror mMirror : mMirrors) {
                    mMirror.set_rotation_speed(0);
                }
                break;
            case 's':
                mSelectedMirror.set_rotation_speed(0.0f);
                break;
            case 'A': {
                final int mSign = random(0, 1) > 0.5f ? 1 : -1;
                final float mSpeed = random(PI * 0.01f, PI * 0.1f) * mSign;
                for (Mirror mMirror : mMirrors) {
                    mMirror.set_rotation_speed(mSpeed);
                }
            }
            break;
            case 'X': {
                for (Mirror mMirror : mMirrors) {
                    mMirror.set_rotation(0);
                }
            }
            break;
            case 'c':
                mSelectedRayID--;
                mSelectedRayID += NUM_RAYS;
                mSelectedRayID %= NUM_RAYS;
                break;
            case 'v':
                mSelectedRayID++;
                mSelectedRayID %= NUM_RAYS;
                break;
        }
    }

    private void line(PVector a, PVector b) {
        line(a.x, a.y, b.x, b.y);
    }

    private void line_to(PVector a, PVector b) {
        line(a.x, a.y, a.x + b.x, a.y + b.y);
    }

    private static class Mirror {

        private final Triangle mTriangleA;
        private final Triangle mTriangleB;
        private final PVector mIntersectionPoint;
        private final PVector mReflectedRay;
        private final PVector mPosition;
        private float mRotation;
        private float mWidth;
        private float mRotationSpeed;
        private boolean mBothSidesReflect = true;

        public Mirror() {
            mPosition = new PVector();
            mReflectedRay = new PVector();
            mRotation = 0.0f;
            mRotationSpeed = 0.0f;
            mWidth = 50.0f;
            mTriangleA = new Triangle();
            mTriangleB = new Triangle();
            mIntersectionPoint = new PVector();
        }

        public void draw(PGraphics g) {
            draw_triangle(g, mTriangleA);
            draw_triangle(g, mTriangleB);
        }

        public PVector intersection_point() {
            return mIntersectionPoint;
        }

        public PVector reflected_ray() {
            return mReflectedRay;
        }

        public void set_both_sides_reflect(boolean pBothSidesReflect) {
            mBothSidesReflect = pBothSidesReflect;
        }

        public boolean reflect(Ray mRay) {
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

        public void set_position(PVector pPosition) {
            mPosition.set(pPosition);
            update_triangles();
        }

        public PVector get_position() {
            return mPosition;
        }

        public void set_width(float pWidth) {
            mWidth = pWidth;
            update_triangles();
        }

        public void set_rotation(float pRotation) {
            mRotation = pRotation;
            update_triangles();
        }

        public float get_rotation() {
            return mRotation;
        }

        public float get_width() {
            return mWidth;
        }

        public void update(float pDelta) {
            if (mRotationSpeed != 0) {
                mRotation += mRotationSpeed * pDelta;
                update_triangles();
            }
        }

        public void set_rotation_speed(float pRotationSpeed) {
            mRotationSpeed = pRotationSpeed;
        }

        private void update_triangles() {
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
            line_to(g, mMidPoint, PVector.mult(pTriangle.normal, 10));
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
