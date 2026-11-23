# External OMV workflow for Rj and Rjp, Embedded or System R.
# 1. Load this script, then use Settings > External OMV files > Read...
#    and select examples/omv/02_external_omv.omv from this repository.
#    Use Read in the settings popup; do not open it as the current jamovi document.
#    The file contains 24 simulated participants, two groups and a few missing values.
#    Other OMV datasets can also be used. Read the file before Run for this test.
# 2. Run this script. It changes dataext only, never the current jamovi data.
#    It adds Rj_row and, for the supplied example, score_change = followup - baseline.
# 3. Enable Show preview in Results and inspect the external dataset.
# 4. Use Save... to export the complete dataext under a NEW name, for example
#    02_external_omv_modified.omv, outside the example folder.
#    Reopen that saved copy to check the new columns and missing values.
#    Keep the supplied input example unchanged for future comparisons.
# Read, preview and Save do not execute the editor script.

stopifnot(is.data.frame(dataext))
if (ncol(dataext) == 0L) {
    # Start with a copy of the current/selected data, or Iris if no data exist.
    dataext <- if (ncol(data) > 0L) as.data.frame(data) else iris
}

dataext$Rj_row <- seq_len(nrow(dataext))
score_columns <- c("baseline_score", "followup_score")
if (all(score_columns %in% names(dataext)) &&
    all(vapply(dataext[score_columns], is.numeric, logical(1)))) {
    dataext$score_change <- as.numeric(dataext$followup_score) - as.numeric(dataext$baseline_score)
    attr(dataext$score_change, "jmv-desc") <- "Change in score: follow-up minus baseline."
}
cat("External dataset:", nrow(dataext), "rows and", ncol(dataext), "columns\n")
print(utils::head(dataext, 10L))

numeric_columns <- names(dataext)[vapply(dataext, is.numeric, logical(1))]
numeric_columns <- setdiff(numeric_columns, "Rj_row")
if (length(numeric_columns) > 0L) {
    column <- if ("score_change" %in% numeric_columns) "score_change" else numeric_columns[1L]
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
