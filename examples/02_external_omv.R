# External OMV workflow for Rj and Rjp, Embedded or System R.
# 1. Optionally use Settings > External OMV files > Read... before Run.
# 2. Run this script. It changes dataext only, never the current jamovi data.
# 3. Enable Show preview in Results and inspect the external dataset.
# 4. Use Save... to export the complete dataext as an OMV file.
# Read, preview and Save do not execute the editor script.

stopifnot(is.data.frame(dataext))
if (ncol(dataext) == 0L) {
    # Start with a copy of the current/selected data, or Iris if no data exist.
    dataext <- if (ncol(data) > 0L) as.data.frame(data) else iris
}

dataext$Rj_row <- seq_len(nrow(dataext))
cat("External dataset:", nrow(dataext), "rows and", ncol(dataext), "columns\n")
print(utils::head(dataext, 10L))

numeric_columns <- names(dataext)[vapply(dataext, is.numeric, logical(1))]
numeric_columns <- setdiff(numeric_columns, "Rj_row")
if (length(numeric_columns) > 0L) {
    column <- numeric_columns[1L]
    values <- dataext[[column]]
    finite <- is.finite(values)
    if (sum(finite) > 1L) {
        hist(values[finite], main = "External dataset distribution", xlab = column,
             col = "#3e6da9", border = "white")
        plot(which(finite), values[finite], main = "External dataset observations",
             xlab = "Row", ylab = column, pch = 19, col = "#3e6da9")
    }
}
cat("Ready: preview or save dataext from Settings.\n")
