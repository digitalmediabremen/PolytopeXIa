import processing.javafx.*;

import teilchen.*;

//https://discourse.processing.org/t/accurate-event-timer/14260/2
//https://stackoverflow.com/questions/13582395/sharing-a-variable-between-multiple-different-threads
ArrayList<Renderable> mMirrors;
Rotatable mSelectedMirror;
Renderable mSelectedRenderable;

int mSelectedRayID;
Constellation mConstellation;
int old_width = 0;
int old_height = 0;
float vw, vh;
Rotatable mDraggedRotatable;
Rotatable mPreviousDraggedRotatable;

void settings() {
  size(1024, 768, FX2D);
}

void setup() {
  mSelectedRayID = 0;
  mMirrors = new ArrayList();
  mConstellation = new Constellation(mMirrors);
  old_width = width;
  old_height = height;
  vw = width / 100f;
  vh = height / 100f;
}

void handleResize() {
  vw = width / 100f;
  vh = height / 100f;
  mConstellation.update();
}

void draw() {
  handleKeyPressed();
  /* update mirror rotation */
  for (Renderable mMirror : mMirrors) {
    if (mMirror instanceof Rotatable) {
      ((Rotatable)mMirror).update(1.0f / frameRate);
    }
  }
  PVector mMousePointer = new PVector(mouseX, mouseY);
  Renderable mClosestRenderable = mConstellation.find_closest(mMousePointer);
  if (mClosestRenderable instanceof Rotatable) {
    mSelectedMirror = (Rotatable)mClosestRenderable;
    mSelectedRenderable = mClosestRenderable;
  } else if (mClosestRenderable != null) {
    mSelectedRenderable = mClosestRenderable;
  } else {
    mSelectedMirror = null;
    mSelectedRenderable = null;
  }
  /* draw */
  background(255);
  /* draw mirrors */
  noFill();
  stroke(0);
  fill(0);
  text(frameRate, 20, 20);
  for (Renderable mRenderables : mMirrors) {
    mRenderables.draw(g);
  }
  if (mPreviousDraggedRotatable != null && mDraggedRotatable instanceof Mirror) {
    noFill();
    stroke(240, 240, 240);
    strokeWeight(2 * vw);
    line(mPreviousDraggedRotatable.get_position().x, mPreviousDraggedRotatable.get_position().y, mDraggedRotatable.get_position().x, mDraggedRotatable.get_position().y);
    strokeWeight(1);
  }
  /* highlight selected mirror */
  if (mDraggedRotatable != null) {
    PVector mSelectedMirrorPosition = mDraggedRotatable.get_position();
    noFill();
    strokeWeight(vw * 2);
    stroke(200, 200, 200);
    if (mSelectedRenderable != null) {
      line(mDraggedRotatable.get_position().x, mDraggedRotatable.get_position().y, mSelectedRenderable.get_position().x, mSelectedRenderable.get_position().y);
    } else {
      line(mDraggedRotatable.get_position().x, mDraggedRotatable.get_position().y, mouseX, mouseY);
    }
    strokeWeight(1);
    stroke(0);
    circle(mSelectedMirrorPosition.x, mSelectedMirrorPosition.y, 4 * vw);
  }

  if (mSelectedMirror != null) {
    PVector mSelectedMirrorPosition = mSelectedMirror.get_position();
    noFill();
    stroke(0);
    circle(mSelectedMirrorPosition.x, mSelectedMirrorPosition.y, 4 * vw);
  }
  if (old_width != width || old_height != height) {
    handleResize();
  }
}

void handleKeyPressed() {
  if (mSelectedMirror == null) return;

  if (keyPressed) {
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

//void mousePressed() {
//  if (mouseButton == LEFT) {
//    mSelectedRayID++;
//    mSelectedRayID %= NUM_RAYS;
//  } else if (mouseButton == RIGHT) {
//    Ray mSelectedRay = mRays.get(mSelectedRayID);
//    PVector mMousePointer = new PVector(mouseX, mouseY);
//    mSelectedRay.origin.set(mMousePointer);
//  }
//}

void mousePressed() {
  mDraggedRotatable = mSelectedMirror;
}

float angle(PVector v1, PVector v2) {
  float a = atan2(v2.y, v2.x) - atan2(v1.y, v1.x);
  if (a < 0) a += TWO_PI;
  return a;
}


void mouseReleased() {
  if (mSelectedRenderable != null && mDraggedRotatable != null && mDraggedRotatable != mSelectedRenderable) {

    PVector direction = PVector.sub(mDraggedRotatable.get_position(), mSelectedRenderable.get_position());
    float heading = angle(direction, PVector.fromAngle(PI));
    float diff = 0;
    if (mPreviousDraggedRotatable != null && mDraggedRotatable instanceof Mirror) {
      PVector previousDirection = PVector.sub( mDraggedRotatable.get_position(), mPreviousDraggedRotatable.get_position());
      diff = angle(direction, previousDirection);
    }
    mDraggedRotatable.set_rotation(heading - diff / 2);
  }

  mPreviousDraggedRotatable = mDraggedRotatable;
  mDraggedRotatable = null;
}

void keyPressed() {
  switch (key) {
  case 'R':
    {
      for (Renderable mRenderable : mMirrors) {
        if (!(mRenderable instanceof Rotatable)) continue;
        final Rotatable mMirror = (Rotatable)mRenderable;
        final int mSign = random(0, 1) > 0.5f ? 1 : -1;
        final float mSpeed = random(PI * 0.01f, PI * 0.1f) * mSign;
        mMirror.set_rotation_speed(mSpeed);
      }
    }
    break;
  case 'I':
    {
      if (mSelectedMirror == null) break;
      final int mSign = random(0, 1) > 0.5f ? 1 : -1;
      final float mSpeed = random(PI * 0.1f, PI * 0.5f) * mSign;
      mSelectedMirror.set_rotation_speed(mSpeed);
    }
    break;
  case 'S':
    for (Renderable mRenderable : mMirrors) {
      if (!(mRenderable instanceof Rotatable)) continue;
      final Rotatable mMirror = (Rotatable)mRenderable;
      mMirror.set_rotation_speed(0);
    }
    break;
  case 's':
    if (mSelectedMirror == null) break;
    mSelectedMirror.set_rotation_speed(0.0f);
    break;
  case 'A':
    {
      final int mSign = random(0, 1) > 0.5f ? 1 : -1;
      final float mSpeed = random(PI * 0.01f, PI * 0.1f) * mSign;
      for (Renderable mRenderable : mMirrors) {
        if (!(mRenderable instanceof Rotatable)) continue;
        final Rotatable mMirror = (Rotatable)mRenderable;
        mMirror.set_rotation_speed(mSpeed);
      }
    }
    break;
  case 'X':
    {
      for (Renderable mRenderable : mMirrors) {
        if (!(mRenderable instanceof Rotatable)) continue;
        final Rotatable mMirror = (Rotatable)mRenderable;
        mMirror.set_rotation(PI / 4);
      }
    }
    break;
  }
}

void line(PVector a, PVector b) {
  line(a.x, a.y, b.x, b.y);
}

void line_to(PVector a, PVector b) {
  line(a.x, a.y, a.x + b.x, a.y + b.y);
}
