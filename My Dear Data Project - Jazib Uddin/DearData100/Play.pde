// Play: one row of plays.csv = one object = one glyph on screen.
// This class is what the Week 10 "coding" criterion looks for:
// every data item is stored and drawn by an instance of this class.
//
// The glyph is a hand-drawn hit circle in the style of my skin:
//   circle colour + letter = rank (skin colours, SS shown as X,
//                            silver X / S when played with HD or FL)
//   circle size            = star difficulty
//   arc around it          = accuracy; its colour = map type (jump pink,
//                            speed white, hybrid pink+white, reading
//                            orange, tech teal)
//   paint drips underneath = misses (no drips = full combo)
//   stem on the right      = mood before -> after
//   mods: speed rings (DT NC HT), HD fades the circle, and marks on the
//         left for HR EZ FL NF RX (colours from my mod menu)

class Play {
  // ---- the data (one field per CSV column) ----
  int id;
  String date;        // YYYY-MM-DD
  String time;        // HH:MM, start of the play (24h)
  String mods;        // stacked with "+", e.g. "HD+DT"; "NM" = no mod
                      // HD DT NC HT HR EZ FL NF RX (RL also read as RX)
  float stars;        // map difficulty, 0-15
  int attempt;        // 1 = first try on that map that day
  boolean passed;     // Y / N
  String rank;        // SS, S, A, B, C, D, FAIL
  float accuracy;     // 0-100
  int misses;
  String mapStyle;    // JUMP, SPEED, HYBRID, READING, TECH
  int moodBefore;     // 1-5
  int moodAfter;      // 1-5
  int energy;         // 1-5
  String place;       // HOME, UNI, TRANSIT, OTHER
  String note;        // free text, shown on hover
  String song;        // song title, may be empty
  String difficulty;  // difficulty name, may be empty
  int duration;       // seconds spent on this play, 0 = not logged

  // ---- where it is drawn ----
  float x, y;         // centre of the cell
  float cellSize;     // height of the cell; the glyph fits inside it

  Play(TableRow row) {
    id = int(cell(row, "id"));
    date = normaliseDate(cell(row, "date"));
    time = normaliseTime(cell(row, "time"));
    mods = cell(row, "mods").toUpperCase();
    if (mods.length() == 0) mods = "NM";
    stars = row.getFloat("stars");
    attempt = row.getInt("attempt");
    passed = cell(row, "passed").equalsIgnoreCase("Y");
    rank = cell(row, "rank").toUpperCase();
    accuracy = parseAccuracy(cell(row, "accuracy"));
    misses = row.getInt("misses");
    mapStyle = cell(row, "mapStyle").toUpperCase();
    moodBefore = row.getInt("moodBefore");
    moodAfter = row.getInt("moodAfter");
    energy = row.getInt("energy");
    place = cell(row, "place");
    note = cell(row, "note");
    song = cell(row, "song");
    difficulty = cell(row, "difficulty");
    duration = parseDuration(cell(row, "duration"));
    checkMods();
  }

  // The text in one column, trimmed, or "" if the cell is empty or the
  // column doesn't exist (older CSVs have no song or difficulty).
  String cell(TableRow row, String column) {
    String value;
    try {
      value = row.getString(column);
    } catch (IllegalArgumentException e) {
      return "";
    }
    if (value == null) return "";
    return trim(value);
  }

  // Accuracy may be typed 96.86 or 96.86%, and Excel sometimes saves a
  // percentage as 0.9686. All three become 96.86.
  float parseAccuracy(String a) {
    float value = float(trim(a.replace("%", "")));
    if (Float.isNaN(value)) {
      println("Play " + id + ": can't read accuracy '" + a + "', using 0");
      return 0;
    }
    if (value > 0 && value <= 1) value *= 100;
    return value;
  }

  // Duration in seconds. Accepts 2:27 (m:ss), 0:02:27 (h:mm:ss), 2m27s,
  // 2m, 147s or a plain 147 (seconds). Empty or unreadable gives 0.
  int parseDuration(String d) {
    d = trim(d.toLowerCase());
    if (d.length() == 0) return 0;
    if (d.indexOf(':') >= 0) {
      String[] parts = split(d, ':');
      int total = 0;
      for (int i = 0; i < parts.length; i++) total = total * 60 + int(trim(parts[i]));
      return total;
    }
    if (d.indexOf('m') >= 0 || d.indexOf('s') >= 0) {
      int total = 0;
      String[] mins = match(d, "(\\d+)\\s*m");
      String[] secs = match(d, "(\\d+)\\s*s");
      if (mins != null) total += int(mins[1]) * 60;
      if (secs != null) total += int(secs[1]);
      return total;
    }
    int value = int(d);
    if (value < 0) value = 0;
    return value;
  }

  // 147 -> "2m27s", 0 -> "-"
  String durationText() {
    if (duration <= 0) return "-";
    if (duration < 60) return duration + "s";
    return (duration / 60) + "m" + nf(duration % 60, 2) + "s";
  }

  // "JUMP" -> "Jump"
  String capitalise(String word) {
    if (word.length() == 0) return word;
    return word.substring(0, 1).toUpperCase() + word.substring(1).toLowerCase();
  }

  // Dates should be typed 2026-10-22, but Excel often changes them, e.g.
  // 22/10/2026, 22/10/26, 22/10/2026 00:00, 22-Oct-26 or even a plain
  // number like 46317 (Excel's day count). Turn all of these into
  // YYYY-MM-DD so a day isn't split into two bars.
  String normaliseDate(String d) {
    d = trim(d);
    // drop a time on the end, e.g. "22/10/2026 00:00"
    if (d.indexOf(' ') > 0) d = d.substring(0, d.indexOf(' '));

    // a plain number: days since 30 Dec 1899, which is how Excel stores dates
    if (d.matches("\\d{5}")) {
      return java.time.LocalDate.of(1899, 12, 30).plusDays(int(d)).toString();
    }

    String[] parts = splitTokens(d, "/-.");
    if (parts.length != 3) {
      println("Play " + id + ": can't read date '" + d + "'");
      return d;
    }
    int day, month, year;
    if (parts[0].length() == 4) {          // 2026-10-22
      year = int(parts[0]);
      month = monthNumber(parts[1]);
      day = int(parts[2]);
    } else {                               // 22/10/2026, 22-Oct-26
      day = int(parts[0]);
      month = monthNumber(parts[1]);
      year = int(parts[2]);
    }
    if (year < 100) year += 2000;
    return year + "-" + nf(month, 2) + "-" + nf(day, 2);
  }

  // "10" -> 10, "Oct" -> 10
  int monthNumber(String m) {
    String[] names = {"JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"};
    String upper = m.toUpperCase();
    for (int i = 0; i < names.length; i++) {
      if (upper.startsWith(names[i])) return i + 1;
    }
    return int(m);
  }

  // Times should be HH:MM; also accept 9:05 or 23:14:00.
  String normaliseTime(String t) {
    String[] parts = split(t, ':');
    if (parts.length < 2) return t;
    return nf(int(trim(parts[0])), 2) + ":" + nf(int(trim(parts[1])), 2);
  }

  // "Song [Difficulty]" for the tooltip, shortened if it's very long.
  String songLabel() {
    String s = song;
    if (difficulty.length() > 0) s += " [" + difficulty + "]";
    s = trim(s);
    if (s.length() > 55) s = s.substring(0, 52) + "...";
    return s;
  }

  // mods is typed by hand, so warn about any code we don't know.
  void checkMods() {
    String[] list = split(mods, '+');
    for (int i = 0; i < list.length; i++) {
      String m = trim(list[i]);
      if (m.equals("RL")) m = "RX";
      boolean known = false;
      for (int k = 0; k < KNOWN_MODS.length; k++) {
        if (KNOWN_MODS[k].equals(m)) known = true;
      }
      if (!known) println("Play " + id + ": unknown mod '" + m + "' ignored");
    }
    // pairs the game doesn't allow together; still drawn, just flagged
    for (int i = 0; i < CLASHING_MODS.length; i++) {
      String a = CLASHING_MODS[i][0];
      String b = CLASHING_MODS[i][1];
      if (hasMod(a) && hasMod(b)) println("Play " + id + ": " + a + " and " + b + " can't be used together - check this row");
    }
  }

  void setPosition(float px, float py, float size) {
    x = px;
    y = py;
    cellSize = size;
  }

  // How much my mood changed: positive = the play cheered me up.
  // A method that returns a value (the Week 5 coding check asks for one).
  int moodChange() {
    return moodAfter - moodBefore;
  }

  // True if this play used the given mod, e.g. hasMod("DT").
  boolean hasMod(String mod) {
    String[] list = split(mods, '+');
    for (int i = 0; i < list.length; i++) {
      String m = trim(list[i]).toUpperCase();
      if (m.equals("RL")) m = "RX";
      if (m.equals(mod)) return true;
    }
    return false;
  }

  // Stars -> radius. Maps above MAX_STARS are drawn at full size.
  float radius() {
    float s = constrain(stars, 0, MAX_STARS);
    return map(s, 0, MAX_STARS, cellSize * 0.12, cellSize * 0.32);
  }

  // The rank as my skin shows it: SS is X, a fail is F.
  String rankLetter() {
    if (rank.equals("FAIL") || !passed) return "F";
    if (rank.equals("SS")) return "X";
    return rank;
  }

  // Misses -> number of drips: 0 = full combo, then 1, 2, 3 or 4 drips.
  int drips() {
    if (misses <= 0) return 0;
    if (misses <= 2) return 1;
    if (misses <= 5) return 2;
    if (misses <= 10) return 3;
    return 4;
  }

  void display(boolean hovered, boolean selected) {
    String letter = rankLetter();
    color c = rankColour(letter, hasMod("HD") || hasMod("FL"));
    float r = radius();
    float cx = -cellSize * 0.1;

    pushMatrix();
    translate(x, y);

    // accuracy: an arc round the circle, empty at MIN_ACCURACY, full at 100%
    float ringR = cellSize * 0.42;
    noFill();
    stroke(255, 35);
    strokeWeight(max(1, cellSize * 0.035));
    ellipse(cx, 0, ringR * 2, ringR * 2);
    float acc = constrain(accuracy, MIN_ACCURACY, 100);
    drawStyleArc(mapStyle, cx, 0, ringR * 2, map(acc, MIN_ACCURACY, 100, 0, TWO_PI), max(1.5, cellSize * 0.06));

    drawDrips(cx, r, c);

    // HD (hidden): the circle and letter fade out
    int alpha = hasMod("HD") ? 110 : 255;

    // hit circle: filled with the rank colour, dark if failed
    strokeWeight(max(1.2, cellSize * 0.04));
    stroke(255, alpha);
    if (passed) fill(c, alpha);
    else fill(FAIL_FILL);
    scribbleCircle(cx, 0, r, id * 0.37);

    drawModMarks(cx, r);

    // rank letter, when there is room for it
    if (cellSize >= 22) {
      fill(passed ? BG : c, alpha);
      textFont(boldFont);
      textAlign(CENTER, CENTER);
      textSize(max(7, r * 1.05));
      text(letter, cx, -r * 0.08);
      textFont(bodyFont);
    }

    drawMoodStem();

    // thin box when hovered, thick box when it's the selected play
    if (hovered || selected) {
      noFill();
      stroke(ACCENT);
      strokeWeight(selected ? 3 : 1.5);
      rectMode(CENTER);
      rect(0, 0, cellSize * 1.15, cellSize * 0.98, 4);
      rectMode(CORNER);
    }
    popMatrix();
  }

  // Draw this glyph somewhere else at another size (used by the selected
  // play card), then put its real position back.
  void displayAt(float px, float py, float size) {
    float oldX = x;
    float oldY = y;
    float oldSize = cellSize;
    setPosition(px, py, size);
    display(false, false);
    setPosition(oldX, oldY, oldSize);
  }

  // The play's details for the selected play card, one line each.
  String[] cardLines() {
    StringList lines = new StringList();
    lines.append(date + "  " + time + "  at " + place.toLowerCase());
    lines.append("Map: " + capitalise(mapStyle) + " " + nf(stars, 0, 2) + "* with " + mods);
    lines.append((passed ? "Rank " + rankLetter() : "Failed") + "  " + nf(accuracy, 0, 2) + "%  "
                 + (misses == 0 ? "FC" : misses + (misses == 1 ? " miss" : " misses")));
    lines.append("Duration: " + durationText() + "  Attempt: #" + attempt);
    lines.append("Mood " + moodBefore + " -> " + moodAfter + "  Energy " + energy + "/5");
    return lines.array();
  }

  // Paint drips running down from the bottom of the circle, one per
  // band of misses, each ending in a small blob.
  void drawDrips(float cx, float r, color c) {
    int n = drips();
    stroke(c);
    strokeWeight(max(1, cellSize * 0.04));
    for (int i = 0; i < n; i++) {
      float dx = cx + map(i, 0, 3, -r * 0.6, r * 0.6);
      float len = cellSize * (0.12 + noise(id, i) * 0.14);
      float top = sqrt(max(0, r * r - (dx - cx) * (dx - cx))) * 0.9;
      line(dx, top, dx, top + len);
      noStroke();
      fill(c);
      ellipse(dx, top + len, cellSize * 0.06, cellSize * 0.07);
      stroke(c);
    }
  }

  // Outline for speed mods, then the column of small marks on the left.
  void drawModMarks(float cx, float r) {
    float ringR = r + cellSize * 0.05;
    float w = max(1, cellSize * 0.03);
    if (hasMod("DT")) drawSpeedRing("DT", cx, 0, ringR, w);
    if (hasMod("NC")) drawSpeedRing("NC", cx, 0, ringR, w);
    if (hasMod("HT")) drawSpeedRing("HT", cx, 0, ringR, w);

    float mx = cx - cellSize * 0.52;
    float m = cellSize * 0.08;
    for (int i = 0; i < MARK_MODS.length; i++) {
      if (hasMod(MARK_MODS[i])) {
        drawModMark(MARK_MODS[i], mx, markY(MARK_MODS[i]), m);
      }
    }
  }

  // HR and EZ share the top slot (they can't be used together in game).
  float markY(String mod) {
    if (mod.equals("HR") || mod.equals("EZ")) return -cellSize * 0.3;
    if (mod.equals("FL")) return -cellSize * 0.1;
    if (mod.equals("NF")) return cellSize * 0.1;
    return cellSize * 0.3;  // RX
  }

  // A small vertical scale on the right of the cell: hollow dot at mood
  // before, arrow head at mood after. Up = happier after playing.
  void drawMoodStem() {
    float sx = cellSize * 0.47;
    float y0 = moodY(moodBefore);
    float y1 = moodY(moodAfter);
    int change = moodChange();
    color stemColour = MOOD_SAME;
    if (change > 0) stemColour = MOOD_UP;
    if (change < 0) stemColour = MOOD_DOWN;

    stroke(stemColour);
    strokeWeight(max(1.5, cellSize * 0.06));
    line(sx, y0, sx, y1);
    float h = cellSize * 0.09;
    noStroke();
    fill(stemColour);
    if (change > 0) triangle(sx - h, y1 + h, sx + h, y1 + h, sx, y1 - h * 0.5);
    else if (change < 0) triangle(sx - h, y1 - h, sx + h, y1 - h, sx, y1 + h * 0.5);
    else ellipse(sx, y1, h * 2, h * 2);
    stroke(stemColour);
    strokeWeight(1);
    fill(BG);
    ellipse(sx, y0, h * 1.3, h * 1.3);
  }

  // Mood 1..5 -> height inside the cell (5 at the top).
  float moodY(int mood) {
    return map(mood, 1, 5, cellSize * 0.36, -cellSize * 0.36);
  }

  boolean isUnderMouse() {
    // the list is moved up by scrollY, so move the mouse down to match
    float my = mouseY + scrollY;
    return mouseInList() && abs(mouseX - x) < cellSize * 0.6 && abs(my - y) < cellSize * 0.5;
  }

  String describe() {
    String s = "";
    if (songLabel().length() > 0) s += songLabel() + "\n";
    s += "#" + id + "   " + date + "  " + time + "  at " + place.toLowerCase() + "\n"
             + mods + "  " + nf(stars, 0, 2) + " stars  " + mapStyle.toLowerCase()
             + "  (attempt " + attempt + ")\n"
             + (passed ? "Passed, rank " + rankLetter() : "Failed")
             + "  " + nf(accuracy, 0, 2) + "%  " + misses + " misses\n"
             + "Mood " + moodBefore + " -> " + moodAfter + "   energy " + energy + "/5";
    if (note.length() > 0) s += "\n\"" + note + "\"";
    return s;
  }
}
