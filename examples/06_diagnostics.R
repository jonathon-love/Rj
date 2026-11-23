# Rj/Rjp diagnostic preview. Try with Embedded and System R.
# Successful Load and Service operations are silent, as in Pj.
# Choose one CASE below, then Run. Errors stay in Results for inspection.
# success: two figures; runtime: error here; nested: error inside a function;
# service: first load 06_service.R with Service... and confirm replacement.
# For a syntax error, uncomment the last line (then restore it before other tests).
CASE <- "success"

if (CASE == "success") {
    cat("Diagnostic preview: successful execution.\n")
    plot(pressure, type="b", pch=19, col="#3e6da9",
         main="Diagnostic preview: native Image")
    mzrjShowSvg(function() plot(pressure, type="b", col="#3e6da9"),
              width=640, height=360, name="diagnostic_svg")
}
if (CASE == "runtime") {
    stop("Runtime probe: caf\u00e9\nThe second line must also remain visible.")
}
if (CASE == "nested") {
    inner <- function() {
        stop("Error inside the inner function.")
    }
    outer <- function() inner()
    outer()
}
if (CASE == "service") {
    mzrjServiceProbe()
}
# SYNTAX_PROBE <- )
