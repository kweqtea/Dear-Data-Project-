// Drawing for mod marks, shared by Play (on each glyph) and the legend.
// Colours follow the groups in my skin's mod menu:
// difficulty reduction = green, increase = red-pink, NC = purple,
// special = light blue.

final color MOD_GREEN = color(90, 230, 110);
final color MOD_RED = color(255, 60, 100);
final color MOD_PURPLE = color(190, 80, 255);
final color MOD_BLUE = color(110, 190, 255);

// Every mod code the log may use. NM = no mod.
String[] KNOWN_MODS = {"NM", "EZ", "NF", "HT", "HD", "HR", "DT", "NC", "FL", "RX"};

// Pairs that can't be combined in osu!stable standard.
String[][] CLASHING_MODS = {{"EZ", "HR"}, {"HT", "DT"}, {"HT", "NC"}, {"DT", "NC"}, {"NF", "RX"}};

// Mods drawn as small marks in the column to the left of a glyph.
String[] MARK_MODS = {"HR", "EZ", "FL", "NF", "RX"};

// A second outline around the circle for speed mods:
// DT solid ring, NC dashed ring (DT with a beat), HT only the bottom half.
void drawSpeedRing(String mod, float cx, float cy, float rr, float w) {
  noFill();
  strokeWeight(w);
  if (mod.equals("DT")) {
    stroke(MOD_RED);
    ellipse(cx, cy, rr * 2, rr * 2);
  } else if (mod.equals("NC")) {
    stroke(MOD_PURPLE);
    for (int i = 0; i < 16; i += 2) {
      arc(cx, cy, rr * 2, rr * 2, TWO_PI * i / 16, TWO_PI * (i + 1) / 16);
    }
  } else if (mod.equals("HT")) {
    stroke(MOD_GREEN);
    arc(cx, cy, rr * 2, rr * 2, 0, PI);
  }
}

// One small mark of size m centred on (x, y).
void drawModMark(String mod, float x, float y, float m) {
  noStroke();
  if (mod.equals("HR")) {
    fill(MOD_RED);
    triangle(x - m, y + m * 0.8, x + m, y + m * 0.8, x, y - m * 1.2);
  } else if (mod.equals("EZ")) {
    fill(MOD_GREEN);
    triangle(x - m, y - m * 0.8, x + m, y - m * 0.8, x, y + m * 1.2);
  } else if (mod.equals("FL")) {
    fill(MOD_RED);
    ellipse(x, y, m * 2.2, m * 2.2);
    fill(BG);
    ellipse(x, y, m * 0.9, m * 0.9);
  } else if (mod.equals("NF")) {
    noFill();
    stroke(MOD_GREEN);
    strokeWeight(max(1, m * 0.45));
    ellipse(x, y, m * 1.8, m * 1.8);
  } else if (mod.equals("RX")) {
    fill(MOD_BLUE);
    rectMode(CENTER);
    rect(x, y, m * 1.8, m * 1.8);
    rectMode(CORNER);
  }
}

// A slightly wobbly circle, like it was drawn with a marker. The wobble
// comes from noise(), so the same seed always gives the same shape.
void scribbleCircle(float cx, float cy, float r, float seed) {
  beginShape();
  int steps = 22;
  for (int i = 0; i < steps + 3; i++) {
    float a = TWO_PI * i / steps;
    float rr = r * (1 + (noise(seed, i % steps * 0.4) - 0.5) * 0.16);
    curveVertex(cx + cos(a) * rr, cy + sin(a) * rr);
  }
  endShape();
}
