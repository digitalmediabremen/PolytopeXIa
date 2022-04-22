package de.hfkbremen.polytopexia.sketches;

import processing.core.PApplet;
import processing.core.PGraphics;
import processing.core.PVector;

import java.util.ArrayList;

public class LaserBeamLogo extends PApplet {

    private static final int GRID_X = 5;
    private static final int GRID_Y = 5;
    private static final int NUM_BEAMS = 5;
    private static final float GRID_SCALE = 64.0f;
    private static final float GRID_DOT_SCALE = 3.0f / GRID_SCALE;
    private static final float BEAM_SCALE = 6.0f / GRID_SCALE;
    private final ArrayList<Beam> mBeams = new ArrayList<>();
    private final ArrayList<Integer> mBeamColors = new ArrayList<>();

    public void settings() {
        size(1024, 768);
    }

    public void setup() {
        mBeamColors.add(color(220, 60, 0));
        mBeamColors.add(color(100, 200, 0));
        mBeamColors.add(color(0, 120, 190));
        regenerateBeamSets();
    }

    public void draw() {
        background(255);
        translate(width / 2.0f, height / 2.0f);
        scale(GRID_SCALE);
        translate(GRID_X / -2.0f, GRID_Y / -2.0f);
        drawGrid();
        for (Beam b : mBeams) {
            b.draw(g);
        }
    }

    public void keyPressed() {
        regenerateBeamSets();
    }

    private void drawGrid() {
        noStroke();
        fill(0);
        for (int y = 0; y < GRID_Y; y++) {
            for (int x = 0; x < GRID_X; x++) {
                circle(x, y, GRID_DOT_SCALE);
            }
        }
    }

    private void regenerateBeamSets() {
        mBeams.clear();
        for (Integer mBeamColor : mBeamColors) {
            PVector mPreviousPosition = null;
            int mColor = mBeamColor;
            for (int i = 0; i < NUM_BEAMS; i++) {
                final Beam b = new Beam();
                if (mPreviousPosition == null) {
                    b.p0.set((int) random(GRID_X), (int) random(GRID_Y));
                } else {
                    b.p0.set(mPreviousPosition);
                }
                b.p1.set((int) random(GRID_X), (int) random(GRID_Y));
                b.beam_color = mColor;
                mBeams.add(b);
                mPreviousPosition = b.p1;
            }
        }
    }

    private class Beam {
        PVector p0;
        PVector p1;
        int beam_color;

        public Beam() {
            p0 = new PVector();
            p1 = new PVector();
            beam_color = color(0);
        }

        public void draw(PGraphics g) {
            g.strokeWeight(BEAM_SCALE);
            g.strokeCap(ROUND);
            g.noFill();
            g.stroke(beam_color);
            g.line(p0.x, p0.y, p1.x, p1.y);
            g.strokeCap(SQUARE);
        }
    }

    public static void main(String[] args) {
        PApplet.main(LaserBeamLogo.class.getName());
    }
}