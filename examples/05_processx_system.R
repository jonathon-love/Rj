# Rj/Rjp development preview: System R process and native graphics.
# 1. Restart jamovi after installing the preview; no dataset is required.
# 2. In Settings choose System R and Run this script. The selected R needs
#    jmvcore and evaluate; dataset transfer does not require jmvconnect.
# 3. Compare with Embedded R. The console identifies the actual R executable.
# 4. To test interruption, set TEST_INTERRUPT to TRUE and Run in System R.
#    While it is waiting, change the interpreter to Embedded. Then set this
#    flag back to FALSE and Run again; the next execution must complete.
# The cancellation probe intentionally runs before any graph is produced.
TEST_INTERRUPT <- FALSE
cat("R version: ", R.version.string, "\n", sep="")
cat("R home: ", R.home(), "\n", sep="")
cat("Unicode output: caf\u00e9, \u03b1, \u65e5\n")
if (TEST_INTERRUPT) {
    cat("Waiting for 30 seconds: change the interpreter to interrupt this run.\n")
    Sys.sleep(30)
}

values <- pressure
print(summary(values))
mzrjShowImage(function() {
    plot(values, type="b", pch=19, col="#3e6da9",
         main="System process check: native Image")
}, width=640, height=400, name="process_image")
mzrjShowSvg(function() {
    plot(values, type="b", pch=19, col="#3e6da9",
         main="System process check: native Svg")
}, width=720, height=420, name="process_svg")
cat("Completed: console, native Image and native Svg.\n")
# Rjp only: an additional column appears under Output when data are selected.
if (is.data.frame(data) && nrow(data) > 0L)
    data$Rj_process_check <- seq_len(nrow(data))
