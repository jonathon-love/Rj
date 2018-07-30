
reportError <- function(result) {
    error <- attr(result, 'condition')
    if ( ! is.null(error$message)) {
        cat('ERROR:', error$message)
    } else {
        cat('ERROR: Unknown error')
    }
}

result <- try({

    if ( ! requireNamespace('jmvconnect', quietly=TRUE))
        stop('To use the system R from jamovi, jmvconnect must be installed', call.=FALSE)

    if (packageVersion('jmvconnect') < '1.0.3')
        stop('To use the system R from jamovi, a newer version of jmvconnect is required', call.=FALSE)

}, silent=TRUE)

if (inherits(result, 'try-error')) {
    reportError(result)
} else {
    result <- try(jmvconnect:::evalRemote("{{CODE}}", "{{DATASET}}", {{ECHO}}, "{{OUTPATH}}", figWidth="{{FIGWIDTH}}", figHeight="{{FIGHEIGHT}}"), silent=TRUE)
    if (inherits(result, 'try-error')) {
        reportError(result)
    } else {
        cat('OK')
    }
}
