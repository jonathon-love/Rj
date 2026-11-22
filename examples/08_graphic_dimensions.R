# Dimension precedence: helper argument > popup value > built-in default.
# Try with both Embedded and System R. No packages or dataset need loading.
# 1. Run. Change Width/Height in the settings popup, then Run again.
#    Only the D3 scatter below follows those global dimensions.
# 2. Change width/height in either explicit helper call, then Run.
#    Only the corresponding graphic changes its size.
# 3. Run again without changes: Chart must not flash or recreate its canvas.
# RESULT_TYPE can also be "svg" or "image" for all three graphics.
RESULT_TYPE <- "html"

mzrjShowScatter(datasets::cars, "speed", "dist", name="global_d3",
    title="D3: dimensions from the popup", result_type=RESULT_TYPE)

mzrjShowPlotly(list(data=list(list(type="bar", x=c("A","B","C"),
    y=c(12,18,15))), layout=list(yaxis=list(title=list(text="Count")))),
    name="fixed_plotly", title="Plotly: explicit 600 x 360",
    width=600, height=360, result_type=RESULT_TYPE)

mzrjShowChart("line", datasets=list(list(label="Illustrative counts",data=c(4,7,5,9))),
    labels=c("Visit 1","Visit 2","Visit 3","Visit 4"),
    name="fixed_chart", title="Chart: explicit 560 x 320",
    width=560, height=320, result_type=RESULT_TYPE)
