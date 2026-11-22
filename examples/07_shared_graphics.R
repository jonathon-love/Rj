# Rj/Rjp: shared offline renderers, no Python or plotting package required.
# Run with both Embedded R and System R. No external dataset is needed.
# Change RESULT_TYPE to "svg" or "image" to compare native outputs.
# Html keeps tooltips, group/legend selection and figure-size controls.
# Svg/Image omit Html accordions and controls; Plotly/Chart Svg is raster-backed.
RESULT_TYPE <- "html" # "html", "svg", "image"

# Built-in iris data; these examples do not modify the current jamovi dataset.
demo <- datasets::iris

mzrjShowScatter(demo, "Sepal.Length", "Petal.Length", group="Species",
    title="Iris: sepal and petal length", name="iris_d3",
    result_type=RESULT_TYPE, width=680, height=420)

mzrjShowBoxplot(demo, "Sepal.Width", group="Species", renderer="plotly",
    title="Sepal width by species: quartiles and observations", name="iris_plotly",
    result_type=RESULT_TYPE, width=680, height=420, accordion_type="bordered")

# Chart.js accepts ordinary R lists. No JavaScript callbacks are required.
means <- tapply(demo$Petal.Length, demo$Species, mean)
mzrjShowChart("bar", datasets=list(list(label="Mean petal length",data=unname(means))),
    labels=names(means), name="iris_chart", title="Descriptive mean petal length",
    options=list(scales=list(y=list(beginAtZero=TRUE))),
    result_type=RESULT_TYPE, width=680, height=380)

# An explicit Plotly specification is also supported, without the R plotly package.
# The toolbar stays hidden by default; config=list(displayModeBar=TRUE) enables it.
mzrjShowPlotly(list(data=list(list(type="scatter", mode="lines+markers",
    x=c(0,3,6,9), y=c(49,52,55,58), name="Illustrative profile")),
    layout=list(xaxis=list(title=list(text="Month")),
                yaxis=list(title=list(text="Illustrative score")))),
    name="profile_plotly", title="Illustrative profile: no model fitted",
    width=680, height=380, result_type=RESULT_TYPE)

cat("Shared graphics complete. Changes to these views do not change the data.\n")
