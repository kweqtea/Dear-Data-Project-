// Dear Data 100 - osu! plays, styled after my osu! skin (draft)
//
// Reads data/plays.csv (one row per osu! play) and draws each play as a
// hand-drawn hit circle on a dark, red-tinted background. Each row of
// glyphs is one day, read left to right in the order the plays happened.
// See Play.pde for what each part of a glyph means; the legend on the
// right explains it too.
//
// data/plays.csv starts with only the header row. Add one row per play
// (or save your log from Excel as CSV UTF-8) and run again.
//
// Keys: 's' saves a PNG of the current frame.

final color BG = color(20, 14, 18);
final color INK = color(240, 235, 237);
final color MUTED = color(150, 132, 140);
final color ACCENT = color(255, 50, 95);
final color FAIL_FILL = color(45, 36, 42);
final color MOOD_UP = color(245, 245, 245);
final color MOOD_DOWN = color(255, 50, 95);
final color MOOD_SAME = color(120, 105, 112);
final color STYLE_READING = color(255, 150, 40);
final color STYLE_TECH = color(40, 215, 205);

// Rank colours from my skin's results screen.
final color RANK_GOLD = color(255, 212, 80);     // X and S
final color RANK_SILVER = color(210, 212, 218);  // X and S with HD or FL
final color RANK_A = color(100, 235, 110);
final color RANK_B = color(90, 185, 255);
final color RANK_C = color(190, 110, 255);
final color RANK_D = color(255, 90, 105);
final color RANK_F = color(150, 135, 145);

// Maps harder than this are drawn at full size.
final float MAX_STARS = 8;
// Accuracy at or below this draws an empty arc.
final float MIN_ACCURACY = 80;

ArrayList<Play> plays = new ArrayList<Play>();
Play selected = null;   // the play last clicked, shown in the card
StringList days = new StringList();
PFont bodyFont;
PFont boldFont;

final int LEGEND_WIDTH = 300;
final int MARGIN = 40;
final int DAY_LABEL_WIDTH = 50;
final int TOTAL_WIDTH = 60;

// Height of one day's row; the glyphs use part of it so rows don't touch.
float rowH = 40;
final float GLYPH_SHARE = 0.8;
int perLine = 1;        // most plays drawn on one line of a day's bar
float[] dayTop;         // top of each day's bar
int[] dayLines;         // how many lines each day's bar has

// Map styles in the order the legend shows them.
String[] STYLES = {"JUMP", "SPEED", "HYBRID", "READING", "TECH"};

void setup() {
  size(1280, 820);
  pixelDensity(displayDensity());
  bodyFont = createFont("SansSerif", 12);
  boldFont = createFont("SansSerif.bold", 12);
  textFont(bodyFont);
  noiseSeed(7);
  loadData("plays.csv");
  layoutGlyphs();
}

void loadData(String filename) {
  // "csv" so quoted song titles with commas in them load correctly
  Table table = loadTable(filename, "header,csv");

  // Excel's "CSV UTF-8" puts an invisible BOM character before the first
  // heading, which would turn "id" into "\uFEFFid". Remove it.
  String first = table.getColumnTitle(0);
  if (first != null && first.startsWith("\uFEFF")) table.setColumnTitle(0, first.substring(1));

  for (TableRow row : table.rows()) {
    // Excel adds empty rows at the end of the export: skip rows with no date
    String date = row.getString("date");
    if (date == null || trim(date).length() == 0) continue;
    Play p = new Play(row);
    if (p.id == 0) p.id = plays.size() + 1;  // no id typed: use the row number
    plays.add(p);
  }

  sortPlays();
  for (Play p : plays) {
    if (!days.hasValue(p.date)) days.append(p.date);
  }
  println("Loaded " + plays.size() + " plays over " + days.size() + " days");
}

// Put plays in date and time order, in case rows were typed out of order.
// Dates are YYYY-MM-DD and times HH:MM, so comparing the text works.
// (Insertion sort: take each play and slide it back to where it belongs.)
void sortPlays() {
  for (int i = 1; i < plays.size(); i++) {
    Play p = plays.get(i);
    String key = p.date + " " + p.time;
    int j = i - 1;
    while (j >= 0 && (plays.get(j).date + " " + plays.get(j).time).compareTo(key) > 0) {
      plays.set(j + 1, plays.get(j));
      j--;
    }
    plays.set(j + 1, p);
  }
}

// Work out where each glyph goes: one bar per day, one column per play.
// A busy day wraps onto extra lines inside a taller bar, so one long day
// doesn't shrink every circle. We try each possible line length and keep
// the one that gives the biggest circles.
void layoutGlyphs() {
  int maxPerDay = 1;
  for (int d = 0; d < days.size(); d++) {
    maxPerDay = max(maxPerDay, playsOn(days.get(d)).size());
  }

  float top = MARGIN + 70;
  float areaW = width - LEGEND_WIDTH - MARGIN * 2 - DAY_LABEL_WIDTH - TOTAL_WIDTH;
  float areaH = height - top - MARGIN;

  int bestPerLine = maxPerDay;
  float bestCell = 0;
  for (int perLine = maxPerDay; perLine >= 1; perLine--) {
    float h = min(areaH / totalLines(perLine), 64);
    float c = min(h * GLYPH_SHARE, areaW / perLine / 1.8);
    if (c > bestCell) {
      bestCell = c;
      bestPerLine = perLine;
    }
  }
  perLine = bestPerLine;
  rowH = min(areaH / totalLines(perLine), 64);
  float cell = bestCell;
  float stepX = min(areaW / perLine, cell * 1.8);

  dayTop = new float[days.size()];
  dayLines = new int[days.size()];
  float y = top;
  for (int d = 0; d < days.size(); d++) {
    ArrayList<Play> today = playsOn(days.get(d));
    dayTop[d] = y;
    dayLines[d] = linesFor(today.size());
    for (int i = 0; i < today.size(); i++) {
      int line = i / perLine;
      int col = i % perLine;
      float px = MARGIN + DAY_LABEL_WIDTH + 10 + stepX * (col + 0.5);
      float py = y + rowH * (line + 0.5);
      today.get(i).setPosition(px, py, cell);
    }
    y += rowH * dayLines[d];
  }
}

// How many lines a day with n plays needs.
int linesFor(int n) {
  return max(1, ceil(n / float(perLine)));
}

// Lines needed for every day if each line holds `lineLength` plays.
int totalLines(int lineLength) {
  int total = 0;
  for (int d = 0; d < days.size(); d++) {
    total += max(1, ceil(playsOn(days.get(d)).size() / float(lineLength)));
  }
  return total;
}

ArrayList<Play> playsOn(String date) {
  ArrayList<Play> result = new ArrayList<Play>();
  for (Play p : plays) {
    if (p.date.equals(date)) result.add(p);
  }
  return result;
}

// Sum of mood changes: positive = osu! left me happier overall.
int totalMoodChange(ArrayList<Play> list) {
  int total = 0;
  for (Play p : list) total += p.moodChange();
  return total;
}

int countPassed(ArrayList<Play> list) {
  int n = 0;
  for (Play p : list) {
    if (p.passed) n++;
  }
  return n;
}

// "2026-10-22" -> "22/10" (day/month) for the label on each row
String dayLabel(String isoDate) {
  String[] parts = split(isoDate, '-');
  if (parts.length != 3) return isoDate;
  return parts[2] + "/" + parts[1];
}

// "1 play", "2 plays"
String plural(int n, String word) {
  return n + " " + word + (n == 1 ? "" : "s");
}

// Rank letter -> colour, silver for X and S when HD or FL was on.
color rankColour(String letter, boolean silver) {
  if (letter.equals("X") || letter.equals("S")) return silver ? RANK_SILVER : RANK_GOLD;
  if (letter.equals("A")) return RANK_A;
  if (letter.equals("B")) return RANK_B;
  if (letter.equals("C")) return RANK_C;
  if (letter.equals("D")) return RANK_D;
  return RANK_F;
}

// Map style -> colour of the accuracy arc.
// Hybrid maps get no single colour: their arc alternates jump and speed.
color styleColour(String style) {
  if (style.equals("JUMP")) return ACCENT;
  if (style.equals("SPEED")) return INK;
  if (style.equals("READING")) return STYLE_READING;
  if (style.equals("TECH")) return STYLE_TECH;
  return MUTED;
}

// The accuracy arc, starting at the top and going clockwise. A hybrid
// arc is made of short pink and white pieces.
void drawStyleArc(String style, float cx, float cy, float d, float sweep, float w) {
  noFill();
  strokeWeight(w);
  if (style.equals("HYBRID")) {
    int pieces = 12;
    for (int i = 0; i < pieces; i++) {
      float a0 = sweep * i / pieces;
      float a1 = sweep * (i + 1) / pieces;
      stroke(i % 2 == 0 ? ACCENT : INK);
      arc(cx, cy, d, d, -HALF_PI + a0, -HALF_PI + a1);
    }
  } else {
    stroke(styleColour(style));
    arc(cx, cy, d, d, -HALF_PI, -HALF_PI + sweep);
  }
}

void draw() {
  drawBackground();
  if (plays.size() == 0) {
    drawTitle("No plays logged yet. Add rows to data/plays.csv (keep the header row) and run again.");
    drawLegend();
    return;
  }

  int up = 0;
  int down = 0;
  for (Play p : plays) {
    if (p.moodChange() > 0) up++;
    if (p.moodChange() < 0) down++;
  }
  drawTitle(plural(plays.size(), "play") + " over " + plural(days.size(), "day") + " ("
            + days.get(0) + " to " + days.get(days.size() - 1) + ").  "
            + round(100.0 * countPassed(plays) / plays.size()) + "% passed.  "
            + plural(up, "play") + " lifted my mood, " + down + " lowered it.");
  drawRowBars();
  drawDayLabels();

  Play hovered = null;
  for (Play p : plays) {
    boolean over = p.isUnderMouse();
    if (over) hovered = p;
    p.display(over, p == selected);
  }

  drawLegend();
  drawSelectedCard();
  if (hovered != null) drawTooltip(hovered);
}

// Clicking a circle selects it. Clicking empty space keeps the last one.
void mousePressed() {
  for (Play p : plays) {
    if (p.isUnderMouse()) selected = p;
  }
}

// The card under the legend: the selected play's song, its difficulty on
// the line below, a big copy of its glyph, and its details. Long names wrap
// instead of being cut, and the card grows upwards to fit them.
void drawSelectedCard() {
  float cw = LEGEND_WIDTH - 12;
  float cx = width - LEGEND_WIDTH - 4;
  float bottom = height - 8;
  float textW = cw - 24;

  if (selected == null) {
    float ch = 120;
    fill(0, 0, 0, 150);
    stroke(255, 30);
    strokeWeight(1.5);
    rect(cx, bottom - ch, cw, ch, 6);
    fill(MUTED);
    noStroke();
    textAlign(CENTER, CENTER);
    textSize(12);
    text("Click a play to see it here", cx + cw / 2, bottom - ch / 2);
    return;
  }

  // work out the wrapped lines first, so we know how tall the card is
  String song = selected.song;
  if (song.length() == 0) song = "Play #" + selected.id;
  textFont(boldFont);
  textSize(13);
  String[] titleLines = wrapText(song, textW, 2);
  textFont(bodyFont);
  textSize(11);
  String[] diffLines = wrapText(selected.difficulty, textW, 3);
  String[] noteLines = new String[0];
  if (selected.note.length() > 0) noteLines = wrapText("\"" + selected.note + "\"", textW, 1);
  String[] stats = selected.cardLines();

  float statsH = stats.length * 15;
  float ch = 10 + titleLines.length * 16 + diffLines.length * 14 + 10 + statsH + noteLines.length * 14 + 14;
  float cy = bottom - ch;

  fill(0, 0, 0, 150);
  stroke(ACCENT);
  strokeWeight(1.5);
  rect(cx, cy, cw, ch, 6);

  float y = cy + 10;
  noStroke();
  textAlign(LEFT, TOP);
  fill(INK);
  textFont(boldFont);
  textSize(13);
  for (int i = 0; i < titleLines.length; i++) {
    text(titleLines[i], cx + 12, y);
    y += 16;
  }
  textFont(bodyFont);
  textSize(11);
  fill(MUTED);
  for (int i = 0; i < diffLines.length; i++) {
    text(diffLines[i], cx + 12, y);
    y += 14;
  }
  y += 10;

  selected.displayAt(cx + 44, y + statsH / 2, 60);

  fill(INK);
  textSize(11);
  textAlign(LEFT, TOP);
  for (int i = 0; i < stats.length; i++) {
    text(stats[i], cx + 96, y + i * 15);
  }
  y += statsH + 4;

  fill(MUTED);
  for (int i = 0; i < noteLines.length; i++) {
    text(noteLines[i], cx + 12, y);
    y += 14;
  }
}

// Split text into lines no wider than w, using the current font size.
// If it needs more than maxLines, the last line ends with "...".
String[] wrapText(String s, float w, int maxLines) {
  StringList lines = new StringList();
  if (trim(s).length() == 0) return lines.array();
  String[] words = splitTokens(s, " ");
  String line = "";
  for (int i = 0; i < words.length; i++) {
    String tryLine = line.length() == 0 ? words[i] : line + " " + words[i];
    if (textWidth(tryLine) <= w || line.length() == 0) {
      line = tryLine;
    } else {
      lines.append(line);
      line = words[i];
    }
  }
  lines.append(line);

  if (lines.size() > maxLines) {
    String last = lines.get(maxLines - 1);
    while (last.length() > 0 && textWidth(last + "...") > w) {
      last = last.substring(0, last.length() - 1);
    }
    lines.set(maxLines - 1, last + "...");
    while (lines.size() > maxLines) lines.remove(lines.size() - 1);
  }
  return lines.array();
}

// Dark background with a red glow and paint specks. randomSeed() makes
// the specks land in the same places every frame.
void drawBackground() {
  background(BG);
  noStroke();
  for (int i = 0; i < 30; i++) {
    fill(140, 20, 50, 5);
    ellipse(width * 0.15, height, 1400 - i * 40, 900 - i * 26);
    fill(120, 15, 40, 4);
    ellipse(width * 0.7, 0, 900 - i * 26, 500 - i * 14);
  }
  randomSeed(42);
  for (int i = 0; i < 260; i++) {
    fill(255, random(15, 70));
    float s = random(1, 2.6);
    ellipse(random(width), random(height), s, s);
  }
  for (int i = 0; i < 8; i++) {
    float sx = random(width - LEGEND_WIDTH);
    float sy = random(height);
    fill(ACCENT, 28);
    for (int k = 0; k < 7; k++) {
      float s = random(2, 9);
      ellipse(sx + random(-14, 14), sy + random(-14, 14), s, s);
    }
  }
}

// A rough, hand-drawn looking line made of short jittered segments.
void roughLine(float x1, float y1, float x2, float y2, float jitter) {
  int steps = int(dist(x1, y1, x2, y2) / 12);
  float px = x1;
  float py = y1;
  for (int i = 1; i <= steps; i++) {
    float t = i / float(steps);
    float nx = lerp(x1, x2, t);
    float ny = lerp(y1, y2, t) + random(-jitter, jitter);
    line(px, py, nx, ny);
    px = nx;
    py = ny;
  }
}

void drawTitle(String subtitle) {
  // red paint slash behind the title
  noStroke();
  fill(ACCENT, 200);
  quad(MARGIN - 12, MARGIN + 12, MARGIN + 330, MARGIN - 4, MARGIN + 336, MARGIN + 10, MARGIN - 8, MARGIN + 26);

  fill(INK);
  textFont(boldFont);
  textAlign(LEFT, TOP);
  textSize(28);
  text("Does osu! cheer me up?", MARGIN, MARGIN - 18);
  textFont(bodyFont);
  fill(MUTED);
  textSize(13);
  text(subtitle, MARGIN, MARGIN + 26);

  randomSeed(5);
  stroke(INK, 200);
  strokeWeight(1.5);
  roughLine(MARGIN, MARGIN + 52, width - LEGEND_WIDTH - MARGIN, MARGIN + 52, 1.2);
}

// A see-through dark bar behind each day so the glyphs stand out from
// the background.
void drawRowBars() {
  float left = MARGIN - 8;
  float right = width - LEGEND_WIDTH - MARGIN;
  for (int d = 0; d < days.size(); d++) {
    float h = rowH * dayLines[d];
    fill(0, 0, 0, 120);
    stroke(255, 18);
    strokeWeight(1);
    rect(left, dayTop[d] + rowH * 0.05, right - left, h - rowH * 0.1, 6);
  }
}

// Date on the left of each row, net mood change that day on the right.
void drawDayLabels() {
  float totalX = width - LEGEND_WIDTH - MARGIN - 10;
  fill(MUTED);
  textSize(10);
  textAlign(RIGHT, TOP);
  text("mood +/-", totalX, MARGIN + 58);
  for (int d = 0; d < days.size(); d++) {
    ArrayList<Play> today = playsOn(days.get(d));
    float y = dayTop[d] + rowH * dayLines[d] / 2;
    fill(MUTED);
    textAlign(LEFT, CENTER);
    text(dayLabel(days.get(d)), MARGIN, y);

    int change = totalMoodChange(today);
    if (change > 0) fill(MOOD_UP);
    else if (change < 0) fill(MOOD_DOWN);
    else fill(MUTED);
    textFont(boldFont);
    textSize(11);
    textAlign(RIGHT, CENTER);
    text((change > 0 ? "+" : "") + change, totalX, y);
    textFont(bodyFont);
    textSize(10);
  }
}

void drawLegend() {
  float lx = width - LEGEND_WIDTH + 10;
  float y = MARGIN - 18;

  noStroke();
  fill(8, 5, 7, 215);
  rect(lx - 24, 0, LEGEND_WIDTH + 14, height);
  stroke(ACCENT);
  strokeWeight(2);
  randomSeed(9);
  roughLine(lx - 24, 0, lx - 24, height, 1.5);

  fill(INK);
  textFont(boldFont);
  textAlign(LEFT, TOP);
  textSize(18);
  text("How to read it", lx, y);
  textFont(bodyFont);
  y += 34;

  // rank -> colour and letter
  legendHeading("Colour + letter = rank (F = failed)", lx, y);
  y += 20;
  String[] letters = {"X", "S", "A", "B", "C", "D", "F"};
  for (int i = 0; i < letters.length; i++) {
    float cx = lx + 12 + i * 36;
    legendCircle(cx, y + 12, 11, letters[i], rankColour(letters[i], false), !letters[i].equals("F"));
  }
  y += 30;
  legendCircle(lx + 12, y + 10, 9, "X", RANK_SILVER, true);
  legendCircle(lx + 36, y + 10, 9, "S", RANK_SILVER, true);
  fill(MUTED);
  textAlign(LEFT, CENTER);
  textSize(11);
  text("silver = with HD or FL", lx + 54, y + 10);
  y += 30;

  // stars -> size
  legendHeading("Size = difficulty (stars)", lx, y);
  y += 20;
  float[] sample = {2, 4, 6, 8};
  for (int i = 0; i < sample.length; i++) {
    float r = map(sample[i], 0, MAX_STARS, 40 * 0.12, 40 * 0.32);
    float cx = lx + 18 + i * 62;
    stroke(INK);
    strokeWeight(1.2);
    noFill();
    ellipse(cx, y + 14, r * 2, r * 2);
    fill(MUTED);
    noStroke();
    textAlign(CENTER, TOP);
    textSize(10);
    text(nf(sample[i], 0, 0) + (i == sample.length - 1 ? "+ stars" : " stars"), cx, y + 30);
  }
  y += 48;

  // accuracy and map style -> arc
  legendHeading("Arc = accuracy (empty = 80% or less)", lx, y);
  y += 20;
  legendArc(lx + 16, y + 13, 85, "SPEED", "85%");
  legendArc(lx + 70, y + 13, 95, "SPEED", "95%");
  legendArc(lx + 124, y + 13, 100, "SPEED", "100%");
  y += 46;

  // map style -> arc colour
  legendHeading("Arc colour = map type", lx, y);
  y += 20;
  for (int i = 0; i < STYLES.length; i++) {
    legendArc(lx + 16 + i * 54, y + 13, 100, STYLES[i], STYLES[i].toLowerCase());
  }
  y += 46;

  // misses -> drips
  legendHeading("Drips = misses", lx, y);
  y += 20;
  String[] dripLabels = {"FC", "1-2", "3-5", "6-10", "11+"};
  for (int i = 0; i < 5; i++) {
    float cx = lx + 14 + i * 50;
    stroke(RANK_B);
    strokeWeight(1.5);
    noFill();
    ellipse(cx, y + 8, 14, 14);
    for (int k = 0; k < i; k++) {
      float dx = cx + map(k, 0, 3, -4, 4);
      line(dx, y + 14, dx, y + 22 + (k % 2) * 3);
    }
    fill(MUTED);
    noStroke();
    textAlign(CENTER, TOP);
    textSize(10);
    text(dripLabels[i], cx, y + 28);
  }
  y += 46;

  // mods -> rings, fade and marks
  legendHeading("Mods (can stack)", lx, y);
  y += 20;
  String[] mods = {"NM", "HD", "DT", "NC", "HT", "HR", "EZ", "FL", "NF", "RX"};
  for (int i = 0; i < mods.length; i++) {
    float cx = lx + 22 + (i % 5) * 52;
    float cy = y + 12 + (i / 5) * 40;
    stroke(INK, mods[i].equals("HD") ? 90 : 255);
    strokeWeight(1.5);
    noFill();
    ellipse(cx, cy, 14, 14);
    drawSpeedRing(mods[i], cx, cy, 10, 1.5);
    drawModMark(mods[i], cx - 16, cy, 3);
    fill(MUTED);
    noStroke();
    textAlign(CENTER, TOP);
    textSize(10);
    text(mods[i].equals("NM") ? "none" : mods[i], cx, cy + 13);
  }
  y += 86;

  // mood before -> after
  legendHeading("Stem = mood before -> after (1 to 5)", lx, y);
  y += 20;
  drawLegendStem(lx + 16, y, 2, 4, MOOD_UP, "happier");
  drawLegendStem(lx + 100, y, 4, 2, MOOD_DOWN, "worse");
  drawLegendStem(lx + 180, y, 3, 3, MOOD_SAME, "same");
  y += 44;

  fill(MUTED);
  textAlign(LEFT, TOP);
  textSize(11);
  text("Rows = days. Right column = mood change.", lx, y);
}

void legendCircle(float cx, float cy, float r, String letter, color c, boolean filled) {
  stroke(INK);
  strokeWeight(1.2);
  if (filled) fill(c);
  else fill(FAIL_FILL);
  ellipse(cx, cy, r * 2, r * 2);
  fill(filled ? BG : c);
  noStroke();
  textFont(boldFont);
  textAlign(CENTER, CENTER);
  textSize(r * 1.05);
  text(letter, cx, cy - 1);
  textFont(bodyFont);
}

void legendArc(float cx, float cy, float acc, String style, String label) {
  noFill();
  stroke(255, 35);
  strokeWeight(1.5);
  ellipse(cx, cy, 24, 24);
  drawStyleArc(style, cx, cy, 24, map(acc, MIN_ACCURACY, 100, 0, TWO_PI), 2.5);
  fill(MUTED);
  noStroke();
  textAlign(CENTER, TOP);
  textSize(10);
  text(label, cx, cy + 16);
}

void drawLegendStem(float x, float y, int before, int after, color c, String label) {
  float y0 = map(before, 1, 5, y + 26, y);
  float y1 = map(after, 1, 5, y + 26, y);
  stroke(c);
  strokeWeight(2.5);
  line(x, y0, x, y1);
  noStroke();
  fill(c);
  if (after > before) triangle(x - 5, y1 + 5, x + 5, y1 + 5, x, y1 - 3);
  else if (after < before) triangle(x - 5, y1 - 5, x + 5, y1 - 5, x, y1 + 3);
  else ellipse(x, y1, 9, 9);
  if (after != before) {
    stroke(c);
    strokeWeight(1);
    fill(BG);
    ellipse(x, y0, 7, 7);
  }
  fill(INK);
  noStroke();
  textAlign(LEFT, CENTER);
  textSize(11);
  text(label, x + 10, y + 13);
}

void legendHeading(String label, float x, float y) {
  fill(INK);
  noStroke();
  textFont(boldFont);
  textAlign(LEFT, TOP);
  textSize(12);
  text(label, x, y);
  textFont(bodyFont);
}

void drawTooltip(Play p) {
  textSize(12);
  String[] lines = split(p.describe(), '\n');
  float tw = 0;
  for (String line : lines) tw = max(tw, textWidth(line));
  tw += 20;
  float th = lines.length * 16 + 12;
  float tx = min(mouseX + 14, width - tw - 10);
  float ty = min(mouseY + 14, height - th - 10);

  fill(10, 6, 9, 240);
  stroke(ACCENT);
  strokeWeight(1.5);
  rect(tx, ty, tw, th, 4);
  noStroke();
  fill(INK);
  textAlign(LEFT, TOP);
  for (int i = 0; i < lines.length; i++) {
    text(lines[i], tx + 10, ty + 7 + i * 16);
  }
}

void keyPressed() {
  if (key == 's' || key == 'S') {
    saveFrame("dear-data-####.png");
    println("Saved a frame");
  }
}
