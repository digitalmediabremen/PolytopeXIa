import java.util.Arrays;
static final int layout_width = 10;
static final int layout_height = 7;
//static final String layout =
//  "    M    " +
//  "  MC CM  " +
//  "   MKMKM " +
//  "  MKMKM  " +
//  "   MC CM " +
//  "     M   ";

//static final String layout =
//  "   M     " +
//  " CM MKM  " +
//  " M C M K " +
//  " K M C M " +
//  "  MKM MC " +
//  "     M   ";

static final String layout =
  "----------" +
  "--M1----M2--" +
  "M3C1-M4-M5----" +
  "--M6C2--C3M7--" +
  "----M8-M9-C4M10" +
  "--M11----M12--" +
  "----------";


//static final String layout =
//  "---M----M-" +
//  "-C--M-C--M" +
//  "--M-MM-M--" +
//  "M--C-M--C-" +
//  "-M----M---";

//static final String layout =
//  "X--XMMX--X" +
//  "--M-M-MC--" +
//  "XM--CC--MX" +
//  "--CM-M-M--" +
//  "-X-XMMX--X";


static final float mirror_diameter = 0.19f;

class Constellation {

  final ArrayList<Renderable> mRenderables;
  final ArrayList<Renderable> mGrid;
  final Mirror[] mMirrors = new Mirror[12];
  final MovingHead[] mLights = new MovingHead[12];

  final RenderContext rc;
  float paddingX, paddingY, constellationWidth, constellationHeight;


  Constellation(ArrayList<Renderable> renderables, RenderContext rc) {
    this.mRenderables = renderables;
    this.mGrid = new ArrayList();
    this.rc = rc;
    update_dimensions();
    create_from_layout(false);
    load();
  }

  public void update_dimensions() {
    paddingX = 10 * rc.vw();
    constellationWidth = (100 - 2 * 10) * rc.vw();
    constellationHeight = constellationWidth * ((layout_height - 1) / (float) (layout_width -1));
    paddingY = (100 * rc.vh() - constellationHeight) / 2f;
  }


  //returns normalized positions between 0 - 1;
  public void update(RenderContext rc) {
    update_dimensions();
    create_from_layout(true);
  }

  float unit_from_meters(float u) {
    return u / ((layout_width - 1) * 3) * (rc.w() - (paddingX * 2));
  }

  void draw(RenderContext rc) {
    textSize(rc.vw() * 1.5);
    textAlign(CENTER, CENTER);

    for (int i = 0; i < layout_width; i++) {
      fill(0);
      text(i, (i * constellationWidth / (layout_width - 1)) + paddingX, paddingY - 5 * rc.vw());
    }

    for (int i = 0; i < layout_height; i++) {
      fill(0);
      text(i, paddingX - 4 * rc.vw(), (i * constellationHeight / (layout_height - 1)) + paddingY);
    }
  }

  public void save() {
    String[] values = new String[12 + 4 * 2];
    for (int i = 0; i < 12; i++) {
      values[i] = str(mMirrors[i].get_rotation_offset());
    }
    for (int i = 0; i < 4; i++) {
      values[i + 12] = str(mLights[i].get_rotation_offset());
      values[i + 12 + 4] = str(mLights[i].get_tilt_offset());
    }
    saveStrings("values.dat", values);
    println("saved");
  }

  public void load() {
    String[] values = loadStrings("values.dat");
    for (int i = 0; i < 12; i++) {
      mMirrors[i].set_rotation_offset(float(values[i]));
    }
    for (int i = 0; i < 4; i++) {
      mLights[i].set_rotation_offset(float(values[i + 12]));
      mLights[i].set_tilt_offset(float(values[i + 12 + 4]));
    }
    println("values loaded");
  }

  public void printConstellation() {
    String[] s = new String[24 + 12];
    for (int i = 0; i < 12; i++) {
      s[i * 2] = str(mMirrors[i].mRotation);
      s[i * 2 + 1] = str(mMirrors[i].sourceAngle);
    }
    for (int i = 0; i < 4; i++) {
      s[i + 24] = str(mLights[i].get_rotation());
      s[i + 24 + 4] = str(mLights[i].get_rotation_offset());
      s[i + 24 + 8] = str(mLights[i].get_tilt_offset());
    }

    //println(Base64.getEncoder().encodeToString(LitheString.zip(Arrays.toString(s))));
    println(Arrays.toString(s));
  }

  public void loadConstellation(String source) {
    String[] s;
    try {
      s = source.split(",");
    }
    catch (Exception e) {
      println(e);
      return;
    }
    for (int i = 0; i < 12; i++) {
      mMirrors[i].mRotation = float(s[i * 2]);
      mMirrors[i].sourceAngle = float(s[i * 2 + 1]);
      mMirrors[i].update_triangles();
    }
    for (int i = 0; i < 4; i++) {
      mLights[i].mRotation = float(s[i + 24]);
      mLights[i].mRotationOffset = float(s[i + 24 + 4]);
      mLights[i].mTiltOffset = float(s[i + 24 + 8]);
      mLights[i].updateRays();
    }
  }

  private void create_from_layout(boolean update) {
    String[][] matches = matchAll(layout, "-|M(\\d{1,2})|C(\\d{1,2})");

    for (int i = 0; i < matches.length; i++) {
      final char c = matches[i][0].charAt(0);
      // normalized 0 - 1 coords
      final float x = (i % layout_width) / (float) (layout_width - 1);
      final float y = (i / layout_width) / (float) (layout_height - 1);
      //adjust to screen coords
      final PVector pos = new PVector(x * constellationWidth, y * constellationHeight).add(paddingX, paddingY);
      if (update) {
        if (c == 'M') {
          Mirror mMirror = (Mirror)mGrid.get(i);
          mMirror.set_width(unit_from_meters(mirror_diameter));
        }
        update_at_position(i, pos);
      } else if (c == 'M') {
        final int id = parseInt(matches[i][1]);
        Mirror mMirror = new Mirror();
        mMirror.set_position(pos);
        mMirror.set_rotation(0);
        mMirror.set_width(unit_from_meters(mirror_diameter));
        mMirror.set_both_sides_reflect(true);
        mRenderables.add(mMirror);
        mGrid.add(mMirror);
        mMirrors[id-1] = mMirror;
      } else if (c == 'C') {
        final int id = parseInt(matches[i][2]);
        MovingHead p = new MovingHead(this);
        mRenderables.addAll(p.mRays);
        p.set_position(pos);
        mRenderables.add(p);
        mGrid.add(p);
        mLights[id-1] = p;
      } else if (c == '-' || c == 'X') {
        Pole p = new Pole(c == 'X');
        p.set_position(pos);
        mRenderables.add(p);
        mGrid.add(p);
      }
    }
  }


  private void update_at_position(int index, PVector position) {
    Renderable mMirror = mGrid.get(index);
    mMirror.set_position(position);
  }

  public Mirror getMirrorById(int id) {
    return mMirrors[id - 1];
  }


  boolean reflect(PVector pRayOrigin, PVector pRayDirection) {
    final ArrayList<Ray> mIntersections = new ArrayList();
    for (Renderable mRenderable : mRenderables) {
      if (!(mRenderable instanceof Mirror)) continue;
      final Mirror mMirror = (Mirror)mRenderable;
      final Ray mRay = new Ray(this);
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


  public Renderable find_closest(PVector position) {
    Renderable pClosest = mGrid.get(1);
    float pClostestDist = Float.POSITIVE_INFINITY;
    for (int i = 0; i < mGrid.size(); i++) {
      Renderable pNext = mGrid.get(i);
      final float pNextDist = PVector.sub(pNext.get_position(), position).magSq();
      if (pNextDist < pClostestDist) {
        pClosest = pNext;
        pClostestDist = pNextDist;
      }
    }

    if (pClostestDist > 1000) return null;
    return pClosest;
  }
}
