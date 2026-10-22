# osu! plays (Dear Data 100 sketch)

Open `DearData100.pde` in Processing (3 or 4) and press Run.

- `DearData100.pde` loads the data, lays out one bar per day, and draws the background, title and legend.
- `Play.pde` is the class: each CSV row becomes one `Play` object that stores and draws itself.
- `Mods.pde` draws the mod marks and the hand-drawn circle (used by the glyphs and the legend).
- `data/plays.csv` holds only the header row. Add one row per play, or keep your log in Excel and save it as "CSV UTF-8" over this file. Until it has rows, the sketch shows a "No plays logged yet" message.

Keep the folder layout: the folder must be called `DearData100`, with all three `.pde` files inside it and the CSV in `data/`.

Styled after my osu! skin: dark red background, rank and mod colours from the skin. Everything is drawn in code.

| Field | Shown as |
|---|---|
| rank | circle colour and letter (X = SS, F = failed; X/S silver with HD or FL) |
| stars | circle size |
| accuracy | arc round the circle (empty = 80% or less, full = 100%) |
| mapStyle | arc colour: jump pink, speed white, hybrid pink+white, reading orange, tech teal |
| misses | paint drips (none = full combo, up to 4 for 11+) |
| mods (e.g. `HD+DT`, `NM` = none) | DT red ring, NC purple dashed ring, HT green half ring, HD faded circle; on the left: HR red spike, EZ green spike, FL red dot, NF green ring, RX blue square |
| moodBefore, moodAfter | stem on the right: white arrow up = happier, red arrow down = worse |
| time | order within the day (busy days wrap onto more lines) |
| song, difficulty | "Song [Difficulty]" in the hover tooltip; in the card you get by clicking a circle, the song with the difficulty on the line below (long names wrap) |
| duration (m:ss, e.g. `2:27`; also 2m27s or seconds) | card: "Duration: 2m27s  Attempt: #1" |
| attempt, energy, place, note | hover tooltip and card |

The right-hand column adds up each day's mood changes. Click a circle to pin its details in the card at the bottom right (it stays until you click another). Press `s` to save a PNG.
