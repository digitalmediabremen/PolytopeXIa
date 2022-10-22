import netP5.*;
import oscP5.*;

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
Rotatable mSelectedRotatable;
Renderable mSelectedRenderable;

int mSelectedRayID;
Constellation mConstellation;
int old_width = 0;
int old_height = 0;
Rotatable mDraggedRotatable;
Rotatable mPreviousDraggedRotatable;
RenderContext rc;
boolean[] pressedKeys = new boolean[256];

State state;
OSCController oscController;
DMXController dmxController;

boolean shiftPressed = false;

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
  oscController = new OSCController(mConstellation);
  dmxController = new DMXController(mConstellation);
  registerMethod("dispose", this);
}

void handleResize() {
  rc.update(width, height);
  mConstellation.update(rc);
}

void dispose() {
  mConstellation.save();
}


void draw() {
  handleKeyPressed();
  /* update mirror rotation */
  for (Renderable mMirror : mMirrors) {
    if (mMirror instanceof Rotatable) {
      ((Rotatable)mMirror).update(1.0f / frameRate);
    }
  }

  dmxController.update();
  oscController.update();
  PVector mMousePointer = new PVector(mouseX, mouseY);
  Renderable mClosestRenderable = mConstellation.find_closest(mMousePointer);
  if (mClosestRenderable instanceof Rotatable) {
    mSelectedRotatable = (Rotatable)mClosestRenderable;
    mSelectedRenderable = mClosestRenderable;
  } else if (mClosestRenderable != null) {
    mSelectedRenderable = mClosestRenderable;
  } else {
    mSelectedRotatable = null;
    mSelectedRenderable = null;
  }
  /* draw */
  background(255);
  /* draw mirrors */

  textAlign(LEFT, CENTER);
  textSize(rc.vw() * 1.5);
  fill(0);
  text("FR " + round(frameRate), 20, 20);
  if (mSelectedRotatable != null) {
    text("ROT " + degrees(mSelectedRotatable.get_rotation()), 100, 20);
    text("ROT-OFS " + degrees(mSelectedRotatable.get_rotation_offset()), 250, 20);
    if (mSelectedRotatable instanceof MovingHead) {
      text("TLT-OFS " + degrees(((MovingHead)mSelectedRotatable).get_tilt_offset()), 450, 20);
    }
  }

  text("DMX " + (dmxController.disabled ? "0" : "1"), 20, 40);



  for (Renderable mRenderables : mMirrors) {
    mRenderables.draw(rc);
  }
  mConstellation.draw(rc);
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

  if (mSelectedRotatable != null) {
    PVector mSelectedMirrorPosition = mSelectedRotatable.get_position();
    noFill();
    stroke(0);
    circle(mSelectedMirrorPosition.x, mSelectedMirrorPosition.y, 4 * rc.vw());
  }
  if (old_width != width || old_height != height) {
    handleResize();
  }
}

void handleKeyPressed() {
  if (mSelectedRotatable == null) return;

  if (keyPressed) {
    final float mMirrorRotationStep = TWO_PI / (2.0f * 360.0f); // 0.5° step size
    switch (key) {
    case 'q':
      mSelectedRotatable.set_rotation(mSelectedRotatable.get_rotation() + mMirrorRotationStep);
      break;
    case 'w':
      mSelectedRotatable.set_rotation(mSelectedRotatable.get_rotation() - mMirrorRotationStep);
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
  mDraggedRotatable = mSelectedRotatable;
}

float angle(PVector v1, PVector v2) {
  float a = atan2(v2.y, v2.x) - atan2(v1.y, v1.x);
  if (a < 0) a += TWO_PI;
  return a;
}

float mapAngle(float a) {
  if (a < 0) a += TWO_PI;
  return a % TWO_PI;
}

void fileSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    println("User selected " + selection.getAbsolutePath());
  }
}

void mouseWheel(MouseEvent event) {
  float factor = 0.001;
  print(pressedKeys);
  if (pressedKeys['T']) {
    if (pressedKeys['C']) factor = 0.01;
    float e = (float)event.getCount() * factor;
    if (mSelectedRotatable != null && mSelectedRotatable instanceof MovingHead) {
      ((MovingHead)mSelectedRotatable).set_tilt_offset(((MovingHead)mSelectedRotatable).get_tilt_offset() + e);
    }
  } else {
    if (pressedKeys['C']) factor = 0.01;
    float e = (float)event.getCount() * factor;
    if (mSelectedRotatable != null) {
      mSelectedRotatable.set_rotation_offset(mSelectedRotatable.get_rotation_offset() + e);
    }
  }
}


void mouseReleased() {
  if (mSelectedRenderable != null && mDraggedRotatable != null && mDraggedRotatable != mSelectedRenderable) {

    PVector direction = PVector.sub(mDraggedRotatable.get_position(), mSelectedRenderable.get_position());
    float heading = angle(direction, PVector.fromAngle(PI));
    // dragged from moving head on mirror
    if (mSelectedRenderable instanceof Mirror && mDraggedRotatable instanceof Rotatable) {
      Mirror m = (Mirror) mSelectedRenderable;
      m.mReflectionSource = direction.normalize();
      m.sourceAngle = heading;
    }
    mDraggedRotatable.set_rotation(heading);
  }

  mPreviousDraggedRotatable = mDraggedRotatable;
  mDraggedRotatable = null;
}

void keyReleased() {
  if (key < 256) pressedKeys[key] = false;
}

void keyPressed() {
  if (key < 256) pressedKeys[key] = true;
  switch (key) {
  case '0':
    {
      if (mSelectedRotatable != null ) {
        mSelectedRotatable.set_rotation_offset(0);

        if (mSelectedRotatable instanceof MovingHead) {
          ((MovingHead)mSelectedRotatable).set_tilt_offset(0);
        } else if (mSelectedRotatable instanceof Mirror) {
          ((Mirror)mSelectedRotatable).mReflectionSource = null;
        }
      }
      break;
    }
  case 'D':
    {
      dmxController.disabled = !dmxController.disabled;
      break;
    }

  case 'S':
    {
      mConstellation.printConstellation();
      break;
    }
  }
}

void line(PVector a, PVector b) {
  line(a.x, a.y, b.x, b.y);
}

void line_to(PVector a, PVector b) {
  line(a.x, a.y, a.x + b.x, a.y + b.y);
}
