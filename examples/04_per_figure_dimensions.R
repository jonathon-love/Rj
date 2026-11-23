# Development Rj/Rjp: per-figure native Image and Svg dimensions.
# Requires the updated preview containing mzrjShowImage() and mzrjShowSvg().
# Works with Embedded and System R. No dataset or extra library is required.
# The first ordinary plot follows Settings > Figure size (px).
plot(pressure, type="b", col="#3e6da9", main="Global popup dimensions")

# These two native results have their own sizes; neither changes the popup.
mzrjShowImage(function() {
    plot(pressure, type="b", col="#3e6da9", main="Native Image: 640 x 400")
}, width=640, height=400, name="pressure_image")

mzrjShowSvg(function() {
    plot(pressure, type="b", col="#3e6da9", main="Native Svg: 720 x 420")
}, width=720, height=420, name="pressure_svg")

# A single dimension preserves the aspect ratio of the global defaults.
mzrjShowImage(function() {
    barplot(c(12,19,8), names.arg=c("Reading","Practice","Discussion"),
            col="#3e6da9", main="Native Image: local width only")
}, width=560, name="counts_image")
