
if (Sys.info()['sysname'] == 'Windows') {
    Sys.setlocale('LC_ALL', '.UTF-8')
} else {
    Sys.setlocale('LC_ALL', 'en_US.UTF-8')
}

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

    if (packageVersion('jmvconnect') < '1.0.7')
        stop('To use the system R from jamovi, a newer version of jmvconnect is required', call.=FALSE)

    if ({{SAVECOLUMNS}} && packageVersion('jmvconnect') < '2.3.13')
        stop('To use the system R with Rj Editor+, a newer version of jmvconnect is required', call.=FALSE)

}, silent=TRUE)

library('methods')  # necessary on windows for some reason

if (inherits(result, 'try-error')) {
    reportError(result)
} else {
    result <- try(jmvconnect:::evalRemote("{{CODE}}", "{{DATASET}}", {{ECHO}}, "{{OUTPATH}}", figWidth="{{FIGWIDTH}}", figHeight="{{FIGHEIGHT}}", columns={{COLUMNS}}, saveColumns={{SAVECOLUMNS}}), silent=TRUE)
    if (inherits(result, 'try-error')) {
        reportError(result)
    } else {
        cat('OK\n')
    }
}
