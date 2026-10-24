# Does osu! cheer me up? (Dear Data 100 starter sketch)

Open `DearData100.pde` in Processing (3 or 4) and press Run.

* `DearData100.pde` loads the data, lays out one row per day and draws the legend.
* `Play.pde` is the class: each CSV row becomes one `Play` object that stores and draws itself.
* `data/plays.csv` holds only the header row. Add one row per play, or keep your log in Excel and save it as "CSV UTF-8" over this file. Until it has rows the sketch shows a "No plays logged yet" message.

Keep the folder layout: the folder must be called `DearData100`, with both `.pde` files inside it and the CSV in `data/`.

|Field|Shown as|
|-|-|
|mapStyle|colour|
|stars|circle size|
|mode|shape (circle, drum, fruit, key)|
|passed|filled (Y) or hollow (N)|
|rank|letter inside the circle (F = fail)|
|accuracy|outer arc (empty = 80% or less, full = 100%)|
|moodBefore, moodAfter|stem beside the glyph: up and green = happier, down and red = worse|
|time|order within the day|
|attempt, misses, energy, place, note|hover tooltip|

The right-hand column adds up each day's mood changes. Press `s` to save a PNG.

