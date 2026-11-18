# 05 — Build Guide: Capstone Dashboard

Follow in order. Estimated time: 60–120 minutes — the cleaning decisions are the learning; the visuals are quick after that.

## Step 0 — Write the question down (do this first, literally)

Before opening Power BI, write this at the top of your notes: **"Where are we losing money?"** Every later decision refers back to it. If a step does not help answer that question, it does not belong in this project.

## Step 1 — Import and audit the raw file

1. Open Power BI Desktop. **Home tab → Get data → Text/CSV** → select `data/superstore.csv` → **Open** → **Transform Data**.
2. **Audit before cleaning.** Scroll the preview and confirm the issues documented in `model.md` with your own eyes:
   - Scroll down: you will hit rows where `Row ID` reads "Person" and the rest is blank — the embedded headers.
   - Check the column headers: `Order Date` shows an "ABC" (text) icon, as do `Sales` and `Profit`.
   - Click the `Order Date` column header dropdown: it will show a large count of blanks (the junk rows).
3. Row count should read **10,800** before cleaning.

## Step 2 — Clean in Power Query (the documented decisions)

Apply these in order. Each maps to a row of the cleaning decisions log in `model.md`.

1. **Remove the 806 junk rows.** Click the dropdown on the `Order Date` column header → uncheck **(null)** / blank → **OK**. Row count should drop to **9,994**. (Do NOT use "Remove Duplicates" anywhere in this project — see decision #5.)
2. **Convert dates.** Select `Order Date` → **Transform tab → Data Type → Date** → Replace current. Repeat for `Ship Date`.
3. **Convert numbers.** Select `Sales` → **Data Type → Decimal Number** → Replace current. Repeat: `Profit` → Decimal Number; `Quantity` → Whole Number; `Discount` → Decimal Number.
4. **Postal Code stays text.** If it was guessed as a number, set it back to Text. Leave its 11 blanks blank.
5. **Keep negative profits.** Do nothing to them. Verify: filter `Profit` < 0 temporarily and confirm rows remain (about 1,871) — then clear the filter.
6. **Rename the query:** right-click `superstore` → **Rename** → `Sales`.
7. **Home tab → Close & Apply.**

## Step 3 — Create the DAX measures

1. Right-click the `Sales` table in the Fields pane → **New measure**. Paste from `dax.md`, one at a time: `Total Sales`, `Total Profit`, `Profit Margin`, `Loss-Making Products`, `Loss Amount`.
2. Set formats: currency (0 decimals) for the money measures, percentage (1 decimal) for `Profit Margin`.
3. Sanity check: a Card with `Total Sales` should read ≈ **$2,297,201** and a Card with `Total Profit` ≈ **$286,397**. If sales read far higher, the junk rows were not removed (Step 2.1). If profit reads much higher, negative-profit rows were filtered out — undo that.

## Step 4 — Build the report page

Create one page named "Where Are We Losing Money?".

### Row 1 — KPI cards
- **Cards** for `Total Sales`, `Total Profit`, `Profit Margin`, `Loss Amount`. Title them plainly. The Loss Amount card in red is the attention-grabber — format its callout value red (Format visual → Callout value → Colors).

### Visual 1 — Profit by sub-category (the headline)
- **Visualizations pane → Clustered bar chart.**
- Y-axis: `Sales[Sub-Category]`. X-axis: `Total Profit`.
- Sort ascending by profit so the worst sub-category is on top: Tables (−$17,725) first, then Bookcases, Supplies, then the profitable ones.
- **Conditional formatting:** Format visual → Bars → Colors → **fx** → Rules: "If value < 0, red; if value >= 0, green". The red bars ARE the answer to the business question.

### Visual 2 — Profit by region
- **Clustered bar chart.** Axis: `Sales[Region]`. Values: `Total Profit`.
- Add `Profit Margin` to Tooltips so hovering a region shows its margin (Central 7.9%, West 14.9%).

### Visual 3 — Profit trend (line chart)
- **Line chart.** X-axis: `Sales[Order Date]` — Power BI will offer a date hierarchy (Year → Quarter → Month); drill to **Month** level. Y-axis: `Total Profit`.
- Read it: does profit dip in specific months, or is the loss steady? Use this to answer "is it getting worse?" in the presentation.

### Visual 4 — Worst products table
- **Table.** Columns: `Sales[Product Name]`, `Total Sales`, `Total Profit`.
- **Filter:** Filters pane → "Filter on this visual" → `Total Profit` → "is less than" → 0. Then sort by `Total Profit` ascending. The Cubify 3D printers and Lexmark printer should top the list.
- This table is your evidence for the "which SKUs" question leadership will ask.

### Slicers
- **Slicer** → `Sales[Category]` (buttons) — so the room can isolate Furniture and watch every other visual narrow to it.
- **Slicer** → `Sales[Order Date]` (Between slider) — for the "which years" question.

## Step 5 — Presenting to leadership (the capstone skill)

Rehearse this 5-minute arc. Do not open with the cleaning steps — open with the answer.

### The arc (5 minutes)
1. **Headline (30 seconds):** "We make money overall — $286k profit on $2.30M sales, a 12.5% margin. But one part of the business loses money, and deep discounting is why."
2. **Where (2 minutes):** Show the sub-category chart. "Furniture runs at a 2.5% margin while Technology and Office Supplies run at 17%. Inside Furniture, Tables lose $17,725 outright, and Bookcases and Supplies lose too. These three are the only loss-making sub-categories."
3. **Why (1 minute):** "The pattern is discounting. Order lines discounted 40% or more lose $108 on average. Lines with no discount make $67. The worst products — the Cubify 3D printers, the Lexmark printer — are all heavily discounted hardware."
4. **What to do (1 minute):** the three actions below.
5. **Close (30 seconds):** "Fix Tables and the discount rule, and the margin story changes without touching the healthy categories."

### Three recommended actions
1. **Reprice or delist the worst Tables SKUs** — starting with the conference tables losing the most per unit.
2. **Cap discounts at 30% without manager approval** — discounts of 40%+ lose money on average, so they should require a sign-off, not be the default.
3. **Review Central region pricing** — the thinnest region (7.9% margin) against West at 14.9%; same products, different outcome, which points to pricing or mix, not the product line itself.

### Questions leadership will ask (and your answers)
- *"Is the data clean? Can we trust these numbers?"* — "Yes. The export had 806 repeated header rows embedded in it; I removed them and verified 9,994 real order lines. Negative profits are real orders, not errors — I kept them deliberately because they are the finding."
- *"Is this just one bad product?"* — "No. Tables as a whole sub-category loses money across 319 order lines, and 18.7% of all order lines lose money. It is a pattern, not an outlier."
- *"Would fixing discounts hurt sales?"* — "That is the right follow-up analysis: compare volume at different discount bands. What this dashboard proves is the current discount levels lose money; the next step is finding the discount level that maximizes profit, not just sales."
- *"What about the other categories?"* — "Technology and Office Supplies are healthy at ~17% margins. The recommendation is to leave their pricing alone and fix Furniture."

## Step 6 — Save

File → Save As → `Capstone_Where_Are_We_Losing_Money.pbix`. This `.pbix` is YOUR file, built by you — it is not part of this kit.

## Common mistakes and fixes

| Symptom | Cause | Fix |
|---|---|---|
| Sales total far above $2.30M | Junk rows not removed | Step 2.1: filter out blank Order Dates |
| Profit total too high | Negative-profit rows deleted | Restore them; they are the finding |
| Sales total far below $2.30M | Deduplicated on Order ID | Re-import; never deduplicate orders |
| Sub-category chart has no red bars | Conditional formatting not applied, or profit summed wrong | Check the measure; apply the < 0 = red rule |
| Trend line shows one dot | Order Date still text | Step 2.2: convert to Date type |
