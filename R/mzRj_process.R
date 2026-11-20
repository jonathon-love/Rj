# System R runs in an owned process tree; never change the engine environment.
.mzRj_systemREnv <- function(version=NULL) {
    removed <- c('R_ENVIRON','R_PROFILE','R_PROFILE_USER','R_ENVIRON_USER',
                 'R_LIBS_SITE','R_LIBS_USER','R_LIBS','R_USER','HOME','R_HOME')
    # POSIX locale names inherited from the engine are not portable to Windows.
    # Let System R choose its own OS locale rather than imposing an English locale.
    if(identical(Sys.info()[['sysname']],'Windows'))
        removed<-unique(c(removed,'LANG','LANGUAGE',grep('^LC_',names(Sys.getenv()),value=TRUE)))
    env <- stats::setNames(rep(NA_character_,length(removed)),removed)
    if(identical(Sys.info()[['sysname']],'Windows')) {
        if(is.null(version)) stop(.('The System R version could not be determined.'),call.=FALSE)
        env['R_LIBS_USER'] <- if(package_version(version)>package_version('4.1.3'))
            file.path(rappdirs::user_data_dir(),'R','win-library','%v') else
            file.path(Sys.getenv('USERPROFILE'),'Documents','R','win-library','%v')
    }
    env
}

.mzRj_stopProcessTree <- function(process, close_connections=TRUE) {
    try(process$kill_tree(close_connections=close_connections),silent=TRUE)
    if(isTRUE(tryCatch(process$is_alive(),error=function(e)FALSE)))
        try(process$kill(close_connections=close_connections),silent=TRUE)
    invisible(NULL)
}

# Merged output and nonzero status follow the previous system2 contract.
# A file-backed stdin avoids blocking while writing a large script into a pipe.
.mzRj_runProcess <- function(command, args, script, env=NULL, checkpoint=NULL, timeout=0) {
    if(!is.character(script)||length(script)!=1L||is.na(script))
        stop(.('The System R script must be a single string.'),call.=FALSE)
    if(!is.numeric(timeout)||length(timeout)!=1L||!is.finite(timeout)||timeout<0)
        stop(.('The process timeout must be a non-negative number.'),call.=FALSE)
    if(!is.null(checkpoint)&&!is.function(checkpoint))
        stop(.('The process checkpoint must be a function.'),call.=FALSE)
    # processx 3.9 requires a complete, non-NA environment vector. Apply the
    # requested overrides to a snapshot, so NA can remove a child variable.
    childEnv <- NULL
    if(!is.null(env)) {
        if(!is.character(env)||is.null(names(env))||anyNA(names(env))||any(!nzchar(names(env)))||anyDuplicated(names(env)))
            stop(.('Process environment overrides must be named strings.'),call.=FALSE)
        childEnv <- Sys.getenv()
        childEnv <- childEnv[!names(childEnv) %in% names(env)[is.na(env)]]
        values <- env[!is.na(env)]
        childEnv[names(values)] <- values
    }
    clock <- function() unname(proc.time()[['elapsed']])
    scriptFile <- tempfile('mzrj-',fileext='.R')
    process <- NULL
    cleaned <- FALSE
    on.exit({
        if(!is.null(process)) {
            if(!cleaned) .mzRj_stopProcessTree(process)
            try(process$kill(),silent=TRUE)
        }
        unlink(scriptFile)
    },add=TRUE)
    if(!is.null(checkpoint)) checkpoint()
    deadline <- if(timeout>0)clock()+timeout else NULL
    expired <- function()!is.null(deadline)&&clock()>=deadline
    writeBin(charToRaw(enc2utf8(script)),scriptFile)
    process <- processx::process$new(command,args,stdin=scriptFile,
        stdout='|',stderr='2>&1',env=childEnv,cleanup_tree=TRUE,encoding='UTF-8',
        windows_hide_window=identical(Sys.info()[['sysname']],'Windows'))
    chunks <- list()
    drain <- function() {
        chunk <- process$read_output(n=65536L)
        if(nzchar(chunk))chunks[[length(chunks)+1L]] <<- chunk
        nzchar(chunk)
    }
    timedOut <- FALSE
    repeat {
        if(expired()){timedOut<-TRUE;break}
        waitMs <- if(is.null(deadline))200 else max(0,min(200,ceiling(1000*(deadline-clock()))))
        if(process$is_incomplete_output())processx::poll(list(process$get_output_connection()),waitMs)
        else process$wait(waitMs)
        drain()
        if(!is.null(checkpoint))checkpoint()
        if(expired()){timedOut<-TRUE;break}
        if(!process$is_alive())break
    }
    if(!timedOut) {
        # Kill descendants even after a normal parent exit, before draining its output.
        .mzRj_stopProcessTree(process,close_connections=FALSE)
        cleaned <- TRUE
        drainDeadline <- clock()+1
        while(clock()<drainDeadline) {
            processx::poll(list(process$get_output_connection()),50)
            received <- drain()
            if(!is.null(checkpoint))checkpoint()
            if(expired()){timedOut<-TRUE;break}
            if(!received&&!process$is_incomplete_output())break
        }
    }
    status <- if(timedOut)124L else process$get_exit_status()
    if(is.null(status)||is.na(status))stop(.('System R stopped without an exit status.'),call.=FALSE)
    text <- paste0(unlist(chunks,use.names=FALSE),collapse='')
    result <- if(nzchar(text))strsplit(text,'\r?\n')[[1]] else character()
    if(status!=0L)attr(result,'status')<-status
    result
}
