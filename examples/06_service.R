# Load with Service..., not Load. This file does not fail while being loaded.
# In 06_diagnostics.R set CASE <- "service", then Run.
# Results must identify this file and the calling line in 06_diagnostics.R.
mzrjServiceProbe <- function() {
    stop("Service function probe: caf\u00e9\nThe complete message must remain visible.")
}
