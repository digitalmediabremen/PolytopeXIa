
static final int layout_width = 10;
static final int layout_height = 5;
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
  "--M----M--" +
  "MC-M-M----" +
  "--MC--CM--" +
  "----M-M-CM" +
  "--M----M--";
  
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


static final float mirror_diameter = 0.25f;

 class Constellation {

  final ArrayList<Renderable> mMirrors;
  final ArrayList<Renderable> mGrid;
  final RenderContext rc;
  float paddingX, paddingY, constellationWidth, constellationHeight;


  Constellation(ArrayList<Renderable> mirrors, RenderContext rc) {
    this.mMirrors = mirrors;
    this.mGrid = new ArrayList();
    this.rc = rc;
    update_dimensions();
    create_from_layout(false);
  }

  public void update_dimensions() {
    paddingX = 2 * rc.vw();
    constellationWidth = (100 - 2 * 2) * rc.vw();
    constellationHeight = constellationWidth * (layout_height / (float) layout_width);
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

  private void create_from_layout(boolean update) {
    for (int i = 0; i < layout.length(); i++) {
      final char c = layout.charAt(i);
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
        add_mirror_at_position(pos);
      } else if (c == 'C') {
        MovingHead p = new MovingHead(this);
        mMirrors.addAll(p.mRays);
        p.set_position(pos);
        mMirrors.add(p);
        mGrid.add(p);
      } else if (c == '-' || c == 'X') {
        Pole p = new Pole(c == 'X');
        p.set_position(pos);
        mMirrors.add(p);
        mGrid.add(p);
      }
    }
  }


  private void update_at_position(int index, PVector position) {
    Renderable mMirror = mGrid.get(index);
    mMirror.set_position(position);
  }

  private void add_mirror_at_position(PVector position) {
    Mirror mMirror = new Mirror();
    mMirror.set_position(position);
    mMirror.set_rotation(0);
    mMirror.set_width(unit_from_meters(mirror_diameter));
    mMirror.set_both_sides_reflect(true);
    mMirrors.add(mMirror);
    mGrid.add(mMirror);
  }

  boolean reflect(PVector pRayOrigin, PVector pRayDirection) {
    final ArrayList<Ray> mIntersections = new ArrayList();
    for (Renderable mRenderable : mMirrors) {
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
