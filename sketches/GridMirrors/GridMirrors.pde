import processing.javafx.*;

import teilchen.*;

ArrayList<Renderable> mMirrors;
Rotatable mSelectedMirror;
int mSelectedRayID;
Constellation mConstellation;
int old_width = 0;
int old_height = 0;

void settings() {
  size(1024, 768, FX2D);
}

void setup() {
  mSelectedRayID = 0;
  mMirrors = new ArrayList();
  mConstellation = new Constellation(mMirrors);
  old_width =frame width;
  old_height = height;
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
  Renderable mSelectedRenderable = mConstellation.find_closest(mMousePointer);
  if (mSelectedRenderable instanceof Rotatable) mSelectedMirror = (Rotatable)mSelectedRenderable;
  else mSelectedMirror = null;
  /* draw */
  background(255);
  /* draw mirrors */
  noFill();
  stroke(0);
  fill(0);
  text(frameRate, 20,20);
  for (Renderable mMirror : mMirrors) {
    mMirror.draw(g);
  }
  /* highlight selected mirror */
  if (mSelectedMirror != null) {
    PVector mSelectedMirrorPosition = mSelectedMirror.get_position();
    noFill();
    stroke(0);
    circle(mSelectedMirrorPosition.x, mSelectedMirrorPosition.y, 30);
  }
  if (old_width != width || old_height != height) {
    mConstellation.update();
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
