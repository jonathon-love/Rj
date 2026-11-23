# Rj / Rjp interface preview: base R only, no additional packages.
# Open Iris Data. In Rjp, select at least two numeric variables.
# Copy this entire script into the editor and press Run.
# Repeat with Embedded and System R to compare the R home paths below.
# Leave FALSE for an initial test without writing any dataset column.
ADD_OUTPUT_COLUMN <- FALSE

cat("Rj / Rjp interface preview\n")
cat("R version:", R.version.string, "\n")
cat("R home:", R.home(), "\n")
cat("Platform:", R.version$platform, "\n\n")

input_available <- exists("data", inherits = FALSE) && is.data.frame(data)
preview_data <- if (input_available) data else data.frame()
numeric_names <- names(preview_data)[vapply(preview_data, is.numeric, logical(1))]
preferred <- c("Sepal.Length", "Sepal.Width")
if (all(preferred %in% numeric_names))
    numeric_names <- c(preferred, setdiff(numeric_names, preferred))

# A fallback keeps the example usable with an empty or unsuitable selection.
# It never replaces the dataset supplied by jamovi.
using_demo <- length(numeric_names) < 2L || nrow(preview_data) == 0L
if (!using_demo) {
    selected <- numeric_names[1:2]
    using_demo <- any(vapply(preview_data[selected], function(x)
        sum(is.finite(x)) < 2L, logical(1)))
}
if (using_demo) {
    preview_data <- datasets::iris[c("Sepal.Length", "Sepal.Width")]
    selected <- names(preview_data)
    cat("Source: built-in Iris demonstration data.\n")
    cat("Select two numeric variables to use your current jamovi data.\n\n")
} else {
    cat("Source: current jamovi data / Rjp selected variables.\n")
    cat("Rows:", nrow(preview_data), "  Columns:", ncol(preview_data), "\n\n")
}

summary_rows <- lapply(selected, function(name) {
    values <- preview_data[[name]]
    valid <- values[is.finite(values)]
    data.frame(Variable = name, N = length(valid),
        Missing_or_invalid = sum(!is.finite(values)),
        Mean = mean(valid), SD = stats::sd(valid), Median = stats::median(valid),
        Minimum = min(valid), Maximum = max(valid), check.names = FALSE)
})
summary_table <- do.call(rbind, summary_rows)
cat("Descriptive statistics\n")
print(summary_table, row.names = FALSE, digits = 4)

x <- preview_data[[selected[1]]]
y <- preview_data[[selected[2]]]
paired <- is.finite(x) & is.finite(y)

# Group drawing commands so each figure is captured as one result image.
{
    graphics::hist(x[is.finite(x)], breaks = "Sturges", col = "#3e6da9",
        border = "white", main = "Distribution", xlab = selected[1],
        ylab = "Count")
    graphics::abline(v = mean(x[is.finite(x)]), col = "#a43d2a", lwd = 2,
        lty = 2)
}

{
    if (sum(paired) >= 2L) {
        graphics::plot(x[paired], y[paired], pch = 19,
            col = grDevices::adjustcolor("#3e6da9", alpha.f = 0.65),
            xlab = selected[1], ylab = selected[2], main = "Paired observations")
        if (length(unique(x[paired])) >= 2L)
            graphics::abline(stats::lm(y[paired] ~ x[paired]),
                col = "#a43d2a", lwd = 2)
    } else {
        graphics::plot.new()
        graphics::title(main = "Paired observations")
        graphics::text(0.5, 0.5, "Fewer than two complete pairs")
    }
}

if (ADD_OUTPUT_COLUMN) {
    if (using_demo || !input_available) {
        cat("\nOutput skipped: demonstration data must not create dataset columns.\n")
    } else {
        values <- data[[selected[1]]]
        finite <- is.finite(values)
        z <- rep(NA_real_, length(values))
        deviation <- stats::sd(values[finite])
        z[finite] <- if (is.finite(deviation) && deviation > 0)
            (values[finite] - mean(values[finite])) / deviation else 0
        data$Rj_preview_z <- z
        cat("\nRj_preview_z prepared from", selected[1], ".\n")
        cat("Only Rjp writes new columns to the jamovi dataset.\n")
    }
} else {
    cat("\nDataset column creation is disabled.\n")
}
cat("Script completed. Check the text and both plots in Results.\n")
# The known resize-persistence issue is not fixed in the first UI preview.
