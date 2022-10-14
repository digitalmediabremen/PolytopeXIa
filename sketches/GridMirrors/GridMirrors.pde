import javax.xml.bind.*;
import javax.xml.bind.annotation.*;
import javax.xml.bind.annotation.adapters.*;
import javax.xml.bind.attachment.*;
import javax.xml.bind.helpers.*;
import javax.xml.bind.util.*;
import com.sun.istack.*;
import com.sun.istack.localization.*;
import com.sun.istack.logging.*;
import com.sun.xml.bind.*;
import com.sun.xml.bind.annotation.*;
import com.sun.xml.bind.api.*;
import com.sun.xml.bind.api.impl.*;
import com.sun.xml.bind.marshaller.*;
import com.sun.xml.bind.unmarshaller.*;
import com.sun.xml.bind.util.*;
import com.sun.xml.bind.v2.*;
import com.sun.xml.bind.v2.model.annotation.*;
import com.sun.xml.bind.v2.model.core.*;
import com.sun.xml.bind.v2.model.impl.*;
import com.sun.xml.bind.v2.model.nav.*;
import com.sun.xml.bind.v2.model.util.*;
import com.sun.xml.bind.v2.runtime.*;
import com.sun.xml.bind.v2.runtime.unmarshaller.*;
import com.sun.xml.bind.v2.schemagen.episode.*;
import com.sun.xml.bind.v2.util.*;
import com.sun.xml.txw2.*;
import com.sun.xml.txw2.annotation.*;
import com.sun.xml.txw2.output.*;
import com.sun.xml.bind.v2.bytecode.*;
import com.sun.xml.bind.v2.model.runtime.*;
import com.sun.xml.bind.v2.runtime.output.*;
import com.sun.xml.bind.v2.runtime.property.*;
import com.sun.xml.bind.v2.runtime.reflect.*;
import com.sun.xml.bind.v2.runtime.reflect.opt.*;
import com.sun.xml.bind.v2.schemagen.*;
import com.sun.xml.bind.v2.schemagen.xmlschema.*;
import ch.bildspur.artnet.*;
import ch.bildspur.artnet.packets.*;
import ch.bildspur.artnet.events.*;

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
Rotatable mDraggedRotatable;
Rotatable mPreviousDraggedRotatable;
RenderContext rc;

byte[] dmxData = new byte[512];
ArtNetClient artnet;


void settings() {
  size(1024, 768, FX2D);
}

void setup() {
  old_width = width;
  old_height = height;
  mSelectedRayID = 0;
  mMirrors = new ArrayList();
  rc = new RenderContext(g, width, height);
  mConstellation = new Constellation(mMirrors, rc);
  artnet = new ArtNetClient(null);
  artnet.start();


  //selectOutput("Select a file to process:", "fileSelected");
}

void handleResize() {
  rc.update(width, height);
  mConstellation.update(rc);
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
    mRenderables.draw(rc);
  }
  if (mPreviousDraggedRotatable != null && mDraggedRotatable instanceof Mirror) {
    noFill();
    stroke(240, 240, 240);
    strokeWeight(2 * rc.vw());
    line(mPreviousDraggedRotatable.get_position().x, mPreviousDraggedRotatable.get_position().y, mDraggedRotatable.get_position().x, mDraggedRotatable.get_position().y);
    strokeWeight(1);
  }
  /* highlight selected mirror */
  if (mDraggedRotatable != null) {
    PVector mSelectedMirrorPosition = mDraggedRotatable.get_position();
    noFill();
    strokeWeight(rc.vw() * 2);
    stroke(200, 200, 200);
    if (mSelectedRenderable != null) {
      line(mDraggedRotatable.get_position().x, mDraggedRotatable.get_position().y, mSelectedRenderable.get_position().x, mSelectedRenderable.get_position().y);
    } else {
      line(mDraggedRotatable.get_position().x, mDraggedRotatable.get_position().y, mouseX, mouseY);
    }
    strokeWeight(1);
    stroke(0);
    circle(mSelectedMirrorPosition.x, mSelectedMirrorPosition.y, 4 * rc.vw());
  }

  if (mSelectedMirror != null) {
    PVector mSelectedMirrorPosition = mSelectedMirror.get_position();
    noFill();
    stroke(0);
    circle(mSelectedMirrorPosition.x, mSelectedMirrorPosition.y, 4 * rc.vw());
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

void fileSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    println("User selected " + selection.getAbsolutePath());
  }
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
    // dragged from moving head on mirror
    if (mSelectedRenderable instanceof Mirror && mDraggedRotatable instanceof MovingHead) {
        Mirror m = (Mirror) mSelectedRenderable;
        m.mIncomingRayDirection = direction.normalize();
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
