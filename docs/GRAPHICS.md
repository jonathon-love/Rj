# Offline graphics helpers in Rj/Rjp

These helpers are available in the editor and in Service scripts, with Embedded R or System R. They use the same vendored D3.js, Plotly.js and Chart.js resources and shared mzGraphics D3/Plotly bundles as Pj. They require neither Python nor the R plotly package and never install user packages.

## Guided helpers

| Helper | Input | Renderer |
| --- | --- | --- |
| `mzrjShowScatter(data, x, y, group=NULL, labels=NULL, ...)` | Complete finite numeric pairs | D3; `renderer="plotly"` optional |
| `mzrjShowLine(data, x, y, group=NULL, labels=NULL, ...)` | Grouped profiles; missing values break lines | D3 or Plotly |
| `mzrjShowBar(data, category, value=NULL, stat="count", ...)` | Count, sum, mean or one value per category | D3 or Plotly |
| `mzrjShowBoxplot(data, variable, group=NULL, ...)` | R type-7 quartiles; observed 1.5-IQR whiskers | D3 or Plotly |
| `mzrjShowHistogram(data, variable, bins="FD", density=FALSE, ...)` | R-selected breaks; explicit left-closed bins, final upper bound included | D3 |
| `mzrjShowBarberJohnson(data, ...)` | Hospital bed utilisation; raw capacity/bed-days/exits or explicit precomputed indicators | Shared D3; four views |
| `mzrjShowHeatmap(matrix, ...)` | Finite numeric matrix with optional row/column labels | Plotly |

Convenience names `mzrjShowPlotlyScatter`, `mzrjShowPlotlyLine`, `mzrjShowPlotlyBar`, `mzrjShowPlotlyBoxplot` and `mzrjShowPlotlyHeatmap` select Plotly directly. These displays are descriptive. No regression, significance test, confidence interval or causal interpretation is implied.

```r
mzrjShowScatter(iris, "Sepal.Length", "Petal.Length", group="Species",
    name="iris_scatter", title="Iris measurements", width=680, height=420)

mzrjShowPlotlyBoxplot(iris, "Sepal.Width", group="Species",
    title="Sepal width by species", width=680, height=420,
    accordion_type="bordered")
```

Replace `iris` with the current `data` frame and its column names. Rjp requires those columns to be selected. Missing/non-finite measurements are excluded from descriptive summaries; factors are categories. Each graphic reports the relevant descriptive convention. No graphics helper consumes R's random number stream.

The guided scatter/line/bar/boxplot calls accept `x_label`, `y_label`, `color`, `name`, `title`, `width`, `height`, `result_type`, `accordion`, `expanded`, and `accordion_type`; Plotly rendering also accepts `config`. For line plots `sort_x`, `connect_gaps` and `show_points` control the displayed profile. This does not make repeated rows independent observations for statistical analysis.

The heatmap helper also accepts `color_scale`, `zmin`, `zmax`, `zmid`, `show_values` (TRUE by default), and `value_label`. Matrix names label the axes; the numeric rows are serialized as JSON arrays. The default uses muted blue, neutral ivory and sage for signed data, or a restrained sequential blue scale for unsigned data. Named Plotly scales remain optional. For a correlation matrix use the default diverging palette and explicit limits:

```r
mzrjShowPlotlyHeatmap(cor(iris[1:4]),title="Iris correlations",
    zmin=-1,zmax=1,zmid=0,
    value_label="Pearson r",width=680,height=480)
```

A custom scale is an ordered list of position/hex-color pairs spanning 0 to 1, for example `color_scale=list(list(0,"#587295"),list(0.5,"#f5f3ee"),list(1,"#54786d"))`. The helper validates the positions and colors before producing a result. Check readability on the rendered graphic, not just the palette's name.

A coefficient of 1 is a perfect positive linear association, -1 is perfect negative association, and 0 indicates no linear association. The example pools species, so between-species differences also contribute; this is not a causal or within-species analysis.

## Explicit Plotly figures

```r
mzrjShowPlotly(list(
    data=list(list(type="scatter",mode="lines+markers",
        x=c(0,3,6),y=c(49,52,55),name="Illustrative profile")),
    layout=list(xaxis=list(title=list(text="Month")),
                yaxis=list(title=list(text="Score")))),
    name="profile",title="Illustrative profile",width=640,height=380,
    config=list(displayModeBar=FALSE))
```

The modebar is hidden by default; `config=list(displayModeBar=TRUE)` or `"hover"` enables it for Html. Hover and legend selection work without the toolbar. Figure/configuration arguments contain ordinary JSON-compatible R lists, without JavaScript callbacks. A list of traces is required even for a single trace. Matrices may be passed as heatmap z values; one-element coordinate vectors remain arrays.

## Chart.js

```r
mzrjShowChart("bar",
    datasets=list(list(label="Responses",data=c(12,19,8))),
    labels=c("Reading","Practice","Discussion"),
    title="Illustrative response counts",name="responses",
    width=600,height=360,
    options=list(scales=list(y=list(beginAtZero=TRUE))))
```

Supported types: bar, line, scatter, bubble, pie, doughnut, radar and polarArea. Scatter/bubble datasets contain lists of points with numeric x/y (and r for bubbles). Options are JSON-compatible R lists; callback functions are rejected. An unchanged chart reuses its canvas when the entire script runs again. Changes to another result or overridden popup dimensions do not invalidate it. Its constructor is isolated from other modules' Chart globals.

## Dimensions, native output and containers

All graphic helpers accept `width=NULL`, `height=NULL`, `result_type="html"`, `accordion=TRUE`, `expanded=TRUE`, `accordion_type="line"`. Explicit width/height take precedence independently over the settings popup; blank popup fields use the existing Rj defaults (400 by 300). Interactive graphic dimensions are integer pixels: width 320–2000, height 240–2000. The existing native-R `mzrjShowImage`/`mzrjShowSvg` helpers retain their prior size contract.

- `html`: interactive output, optional line or bordered accordion. The same shared size slider and normal-flow layout as Pj keep subsequent results below the figure. Chart follows its existing Pj canvas behavior.
- `svg`: native jamovi Svg result, without an Html accordion/size wrapper. D3 produces vector SVG. Plotly and Chart export a **PNG embedded inside SVG**; these are raster-backed, not vector artwork.
- `image`: a browser-rendered PNG is acknowledged once and replaced by a native jamovi Image. It does not rerun the user's code. Preparation takes place offscreen, without a flashing placeholder. Native resize/save/reopen are supported.

Set `accordion=FALSE` to omit the Html container; `expanded=FALSE` requires an accordion. Native Svg/Image ignore Html container controls. Titles/labels are treated as text, not executable markup.

`mzrjShowHtml(content, ...)` deliberately accepts trusted Html and scripts, like an editor-generated result. It is distinct from label/configuration arguments. The low-level `mzrjShowD3(payload, ...)` consumes the shared renderer contract for advanced host-prepared payloads; it is not an inference API. No Python statistical API has been added to Rj.

Examples: [07 shared renderers](../examples/07_shared_graphics.R), [08 dimension precedence](../examples/08_graphic_dimensions.R), [09 guided displays](../examples/09_guided_graphics.R). Try both R interpreters and all three result types. Existing scripts 05/06 remain regression checks for process control and diagnostics/Service.

## Maintenance and validation

Editable common renderer sources live in mzGraphics. Modules carry generated bundles plus their content manifest and vendor licenses; runtime does not reach into another checkout. Do not edit minified bundles or create a separate R-specific D3/Plotly rendering engine. The adapter owns R validation, summaries, translation, stable result names and native result acknowledgement.

Automated Windows and Linux engine checks cover both R interpreters, native acknowledgement/save/reload, explicit/global dimensions, input escaping and the existing Rj/Rjp lifecycle. Offline Chromium checks cover actual rendered content under CSP, including colored heatmap cells, Chart canvas reuse and multiple-result layout. Windows examples 07/08/09 passed maintainer visual acceptance. Example 09 passed maintainer checks with both R modes in WSL2; the external OMV preview/save workflow was also accepted. These checks do not claim macOS GUI acceptance.

## Hospital Barber–Johnson nomograms

`mzrjShowBarberJohnson` provides TOI–ALOS, TOI–BTO, ordered ward trajectories and vertically faceted views. It accepts locally selected reference scenarios without treating them as universal clinical targets. It returns indicators in an R data frame and can add a native indicator table. See the complete [English guide](BARBER_JOHNSON.md), [guida italiana](BARBER_JOHNSON_IT.md) and self-contained `examples/10_barber_johnson.R`; the matching synthetic CSV is in `examples/data`. No optional R package or Python is needed.

Native Image conversion sends one PNG at a time and waits for acknowledgement before advancing. Cancelling or changing to Html discards obsolete captures; capture failures are visible. Resizing one native Image preserves the other results, table and original dimension bases without executing R or restarting capture, including across jamovi's INIT/save/fresh-RUN phases. These fixes apply to other graphic helpers too. Native Svg containers allow their requested size without internal clipping. The known lower-left or unresponsive native grip on some Linux installations remains a jamovi limitation: explicit width/height or popup dimensions are the alternative.
