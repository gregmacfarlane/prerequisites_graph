# Course prerequisite graph

This project contains an interactive Shiny application for exploring prerequisite courses in two versions of the program:

- 2025–2026 (`25-26`)
- 2026–2027 (`26-27`)

The graph is rendered with [`visNetwork`](https://datastorm-open.github.io/visNetwork/), using JSON files as the data source.

## Run the app

Install the required R packages once:

```r
install.packages(c("shiny", "visNetwork", "jsonlite"))
```

From this project directory, run:

```r
shiny::runApp(".")
```

Alternatively, open `app.R` in RStudio and select **Run App**.

## Using the app

The sidebar provides:

- A program version selector for `25-26` or `26-27`
- A flexible force-directed layout
- A left-to-right layout based on course level
- A physics toggle and stabilization button

Courses can be dragged, zoomed, and repositioned. The legend is loaded from the selected JSON file.

The capstone requirement panel is year-dependent:

- `25-26`: 12 hours of CE Breadth must be completed before starting CE 471.
- `26-27`: 12 hours of CE Breadth and one CE Design class must be completed before starting CE 472.

## Project files

| File | Purpose |
| --- | --- |
| `app.R` | Main Shiny application |
| `graph_2526.json` | Nodes, edges, and legend for the 2025–2026 program |
| `graph_2627.json` | Nodes, edges, and legend for the 2026–2027 program |
| `graph.R` | Earlier standalone `visNetwork` renderer; use `app.R` for the multi-year app |

## JSON structure

Each program file has three top-level fields:

```json
{
  "nodes": [],
  "edges": [],
  "legend": []
}
```

### Nodes

Each node represents a course:

```json
{
  "id": "MATH_112",
  "label": "MATH 112",
  "title": "MATH 112",
  "group": "MATH",
  "level": 1
}
```

Use unique, stable IDs without spaces. The `label` is the course name shown in the graph. The `group` controls the course color and legend category. The `level` is used by the hierarchical layout; 100-level courses use `1`, 200-level courses use `2`, and so on.

### Edges

Edges point from prerequisite to course:

```json
{
  "from": "MATH_112",
  "to": "MATH_113",
  "dashed": false
}
```

Set `dashed` to `true` for relationships that should be displayed as dashed lines. The app maps this JSON field to the `dashes` field expected by `visNetwork`.

Every `from` and `to` value should match a node `id` in the same program file.

### Legend

Legend entries define the display name and color for each group:

```json
{
  "group": "BREADTH",
  "label": "CE Breadth",
  "color": "#76B7B2"
}
```

## Adding another program year

1. Create a new JSON file following the existing schema.
2. Add the file to `graph_files` near the top of `app.R`:

   ```r
   graph_files <- c(
     "25-26" = "graph_2526.json",
     "26-27" = "graph_2627.json",
     "27-28" = "graph_2728.json"
   )
   ```

3. Add the new year to the `program_year` `selectInput` choices.
4. Update the year-specific requirement logic in `output$requirement_panel` if the capstone requirements change.

## Data checks

Before running the app, validate that the JSON is well-formed:

```bash
jq empty graph_2526.json
jq empty graph_2627.json
```

Also check that every edge endpoint refers to a node ID in the same file. Unmatched IDs can cause `visNetwork` to omit edges or create unexpected graph behavior.
