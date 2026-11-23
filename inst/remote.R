# Child process protocol: dataset/results use RDS, independently of jmvconnect.
. <- function(text) text
reportError <- function(result) {
    error <- attr(result, 'condition')
    message <- if(!is.null(error$message))error$message else .('Unknown error')
    saveRDS(list(message=enc2utf8(message)), "{{OUTPATH}}")
    cat('ERROR_RDS\n');flush(stdout())
}

result <- try({
    source({{EVALUATOR}},local=TRUE)
    if(Sys.info()[['sysname']]=='Windows')Sys.setlocale('LC_ALL','.UTF-8')
    missing <- c('jmvcore','evaluate')[!vapply(c('jmvcore','evaluate'),
        requireNamespace,logical(1),quietly=TRUE)]
    if(length(missing))stop(paste(.('System R is missing required packages:'),
        paste(missing,collapse=', ')),call.=FALSE)
    library('methods')
    openNew <- function(data=NULL,title='') {
        if(requireNamespace('jmvReadWrite',quietly=TRUE)) {
            if(packageVersion('jmvReadWrite')>'0.4.10')
                jmvReadWrite:::jmvOpn(dtaFrm=data,dtaTtl=title,rtnOut=FALSE)
            else cat(.('To use the system R from jamovi, a newer version of jmvReadWrite (> 0.4.9) is required.'))
        } else if(Sys.info()[['sysname']] %in% c('Darwin','Windows'))
            cat(.('openNew() requires that jmvReadWrite is installed in your system R installation.'))
        else cat(.("openNew() is not available under 'system R' on Linux systems."))
    }
    dataextContext<-new.env();dataextContext$data<-readRDS({{DATAEXT_INPUT}})
    data<-readRDS({{DATA_INPUT}})
    results<-.mzRj_eval("{{CODE}}",data,{{ECHO}},
        figWidth="{{FIGWIDTH}}",figHeight="{{FIGHEIGHT}}",saveColumns={{SAVECOLUMNS}},
        dataextEnv=dataextContext,
        sourceInfo=if(exists('.mzRj_sourceInfo',inherits=TRUE)).mzRj_sourceInfo else NULL)
    saveRDS(dataextContext$data,{{DATAEXT_OUTPUT}})
    saveRDS(results,"{{OUTPATH}}")
},silent=TRUE)
if(inherits(result,'try-error')) reportError(result) else {cat('OK\n');flush(stdout())}
