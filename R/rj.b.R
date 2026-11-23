
RjClass <- R6::R6Class(
    "RjClass",
    inherit = RjBase,
    active=list(
        saveColumns=function() FALSE
    ),
    private = list(
        .editorUiOnly=FALSE,
        .graphicCaptureOnly=FALSE,
        .resultsUiOnly=FALSE,
        .postInit=function() .mzRj_omvInfo(self),
        .run = function() {
            if(private$.graphicCaptureOnly) {
                on.exit({private$.graphicCaptureOnly<-FALSE;private$.resultsUiOnly<-FALSE;
                    .mzRj_clearGraphicCapture(self)},add=TRUE)
                .mzRj_applyGraphicCapture(self)
                return()
            }
            if(private$.resultsUiOnly) {private$.resultsUiOnly<-FALSE;return()}
            if(nzchar(self$options$graphicCapture)) .mzRj_clearGraphicCapture(self)
            if(.mzRj_omvAction(self)) return()
            if (isTRUE(self$options$saveEditorScript)) {
                .mzRj_saveEditor(self)
                return()
            }
            if (private$.editorUiOnly)
                return()

            previousExternal <- .mzRj_omvState(self)
            self$results$clear()
            .mzRj_omvRestore(self,previousExternal)

            if (isTRUE(self$options$editorCleared)) {
                eval('', self$data, FALSE, self$results, saveColumns=self$saveColumns)
                return()
            }
            context <- new.env(parent=emptyenv())
            context$data <- .mzRj_dataext(self)
            code <- .mzRj_editorCode(self)
            sourceInfo <- .mzRj_editorSources(self)
            sourceInfo$messages <- c(.mzRj_remoteMessages(self), .mzRj_graphicsMessages(self), .mzRj_barberJohnsonMessages(self))
            sourceInfo$graphicsAssets <- .mzRj_graphicsAssets()
            echo <- self$options$output == 'echo'
            figWidth  <- self$options$figWidth
            figHeight <- self$options$figHeight

            if (self$options$R == 'bundled') {

                eval(code, self$data, echo, self$results,
                     figWidth=figWidth, figHeight=figHeight,
                     saveColumns=self$saveColumns,dataextEnv=context,sourceInfo=sourceInfo)

            } else {

                scriptPath <- system.file('remote.R', package='Rj', mustWork=TRUE)
                outputPath <- tempfile()
                dataextInput <- tempfile(fileext='.rds');dataextOutput <- tempfile(fileext='.rds')
                evaluatorPath <- tempfile(fileext='.R')
                dataInput <- tempfile(fileext='.rds')
                on.exit(unlink(c(outputPath,dataextInput,dataextOutput,evaluatorPath,dataInput)),add=TRUE)
                saveRDS(context$data,dataextInput)
                saveRDS(self$data,dataInput)
                writeLines(c('.mzRj_barberJohnsonPrepare <-',deparse(.mzRj_barberJohnsonPrepare),'.mzRj_graphicsFactory <-',deparse(.mzRj_graphicsFactory),'.mzRj_eval <-',deparse(eval),'.mzRj_sourceInfo <-',deparse(sourceInfo),'.mzRj_messages <-',deparse(.mzRj_remoteMessages(self)),
                    '. <- function(text) {value <- .mzRj_messages[[text]];if(is.null(value))text else value}'),evaluatorPath)

                outputPath <- gsub('\\', '/', outputPath, fixed=TRUE)

                code <- gsub('\\', '\\\\', code, fixed=TRUE)
                code <- gsub('"', '\\"', code, fixed=TRUE)

                script <- readLines(scriptPath)
                script <- paste0(script, collapse='\n')
                script <- gsub('{{DATA_INPUT}}', deparse1(dataInput), script, fixed=TRUE)
                script <- gsub('{{OUTPATH}}', outputPath, script, fixed=TRUE)
                script <- gsub('{{FIGWIDTH}}', figWidth, script, fixed=TRUE)
                script <- gsub('{{FIGHEIGHT}}', figHeight, script, fixed=TRUE)
                script <- gsub('{{ECHO}}', echo, script, fixed=TRUE)

                script <- gsub('{{SAVECOLUMNS}}', self$saveColumns, script, fixed=TRUE)
                script <- gsub('{{EVALUATOR}}', deparse1(evaluatorPath), script, fixed=TRUE)
                script <- gsub('{{DATAEXT_INPUT}}', deparse1(dataextInput), script, fixed=TRUE)
                script <- gsub('{{DATAEXT_OUTPUT}}', deparse1(dataextOutput), script, fixed=TRUE)
                script <- gsub('{{CODE}}', code, script, fixed=TRUE)

                R <- private$.findR()

                # Retain the existing Windows cli shutdown workaround for older R.
                if(identical(Sys.info()[['sysname']],'Windows')) {
                    script <- paste0(script, '\ntry({
    cli_dll <- getLoadedDLLs()[["cli"]]
    if(!is.null(cli_dll)) dyn.unload(cli_dll[["path"]])
}, silent=TRUE)\n')
                }

                result <- .mzRj_runProcess(
                    command=R$path,
                    args=c('--no-save','--no-restore','--slave','--encoding=UTF-8'),
                    script=script,
                    env=.mzRj_systemREnv(R$rcv),
                    checkpoint=function() private$.checkpoint(flush=FALSE),
                    errorMarker='ERROR_RDS')
                status <- attr(result,'status')
                if(!is.null(status) && status!=0L)
                    stop(paste(.("System R stopped with exit status"),status,
                        paste(tail(result,5L),collapse='\n')),call.=FALSE)
                receivedResults <- FALSE

                for (line in result) {
                    if (jmvcore::startsWith(line, 'ERROR: ') || identical(line,'ERROR_RDS')) {

                        message <- if(identical(line,'ERROR_RDS'))readRDS(outputPath)$message else substring(line, 8)
                        if (message == 'Memory segment version is too new')
                            message <- 'A newer version of jmvconnect is required'
                        if (message == 'Memory segment version is too old')
                            message <- 'A newer version of jamovi is required'
                        stop(message, call.=FALSE)

                    } else if (line == 'OK') {
                        receivedResults <- TRUE
                        results <- readRDS(file=outputPath)
                        context$data <- readRDS(dataextOutput)
                        for (item in results$items)
                            self$results$add(item)
                    }
                }

                if(!receivedResults)
                    stop(.("System R did not return results."),call.=FALSE)

                unlink(outputPath)

                # options <- jmvcore::Options$new();
                # text <- jmvcore::Preformatted$new(options, 'output');
                # self$results$add(text)
                #
                # text$setContent(result)
            }

            .mzRj_stageDataext(self,context$data,if(is.null(previousExternal$source_name))'' else previousExternal$source_name)
            .mzRj_omvInfo(self)
            .mzRj_omvPreview(self)
            .mzRj_bindImages(self)
        },
        .render=function(image, ...) {
            if(is.list(image$state) && !is.null(image$state$mzrj_nativePng)) {
                bitmap<-png::readPNG(jsonlite::base64_dec(image$state$mzrj_nativePng))
                grid::grid.raster(bitmap,width=grid::unit(1,'npc'),
                    height=grid::unit(1,'npc'),interpolate=TRUE)
                return(TRUE)
            }
            recordedPlot <- image$state

            for (i in seq_along(recordedPlot[[1]])) {
                symbol <- recordedPlot[[1]][[i]][[2]][[1]]
                if ('NativeSymbolInfo' %in% class(symbol)) {
                    if (is.null(symbol$package)) {
                        name <- symbol$dll[['name']]
                    } else {
                        name <- symbol$package[['name']]
                    }
                    dll <- getLoadedDLLs()[[name]]
                    nativeSymbol <- getNativeSymbolInfo(
                        name = symbol$name,
                        PACKAGE = dll,
                        withRegistrationInfo = TRUE)
                    recordedPlot[[1]][[i]][[2]][[1]] <- nativeSymbol
                }
            }

            print(recordedPlot)
            TRUE
        },
        .findR = function() {

            os <- Sys.info()[['sysname']]

            if (os == 'Darwin') {
                version <- Sys.readlink('/Library/Frameworks/R.framework/Versions/Current')
                path <- file.path('/Library/Frameworks/R.framework/Versions', version)
                path <- file.path(path, 'Resources', 'bin', 'R')

                if (file.exists(path))
                    return(list(path = path))
                if (file.exists('/usr/bin/R'))
                    return(list(path = '/usr/bin/R'))
                if (file.exists('/usr/local/bin/R'))
                    return(list(path = '/usr/local/bin/R'))
                if (file.exists('/opt/local/bin/R'))
                    return(list(path = '/opt/local/bin/R'))

            } else if (os == 'Windows') {

                # Try HKEY_LOCAL_MACHINE first
                regHLM <- file.path("SOFTWARE", "R-core", "R64", fsep = "\\")
                entries <- try(readRegistry(regHLM,
                                            hive = "HLM",
                                            maxdepth = 2,
                                            view = "64-bit"))

                # If not found, try HKEY_CURRENT_USER
                if (inherits(entries, 'try-error')) {
                    regHCU <- file.path("SOFTWARE", "R-core", "R64", fsep = "\\")
                    entries <- try(readRegistry(regHCU,
                                                hive = "HCU",
                                                maxdepth = 2,
                                                view = "64-bit"))
                }

                # If entries are invalid or missing
                if (inherits(entries, 'try-error')) {
                    stop(.("Could not find R installation in the Windows registry (HLM or HCU)"))
                }

                # Extract version and path
                rcv <- entries$`Current Version`
                path <- file.path(entries$InstallPath, "bin", "x64", "R.exe")

                # If InstallPath is nested, check for alternate structure
                if (is.null(entries$InstallPath) && !is.null(entries[[1]])) {
                    installPath <- entries[[1]]$InstallPath
                    dirs <- strsplit(installPath, split='\\', fixed=TRUE)[[1]]
                    rDir <- dirs[length(dirs)]
                    rcv <- strsplit(rDir, '-', fixed=TRUE)[[1]][2]  # R-4.5.2 => 4.5.2
                    path <- file.path(installPath, "bin", "x64", "R.exe")
                }

                # Normalize the path for Windows
                path <- gsub("/", "\\", path, fixed = TRUE)

                # Validate the path
                if (file.exists(path)) {
                    return(list(path = path, rcv = rcv))
                }

                stop(.("Could not locate R.exe at the specified registry path"))

            } else {  # For Linux and other Unix-like systems
                path <- unname(Sys.which('R'))
                if (file.exists(path))
                    return(list(path = path))
                if (file.exists('/usr/bin/R'))
                    return(list(path = '/usr/bin/R'))
                if (file.exists('/usr/local/bin/R'))
                    return(list(path = '/usr/local/bin/R'))
            }

            stop(.('Could not find system R'))
        }),
    public=list(
        asSource=function() {
            if ( ! self$options$output == 'echo')
                return(self$options$code)
            else
                return('')
        },
        .load=function(vChanges=character()) {
            private$.editorUiOnly <- FALSE
            private$.graphicCaptureOnly <- FALSE
            private$.resultsUiOnly <- FALSE

            jmvcore:::initProtoBuf()

            path <- private$.statePathSource()
            Encoding(path) <- 'UTF-8'

            if (base::file.exists(path)) {
                conn <- file(path, open="rb", raw=TRUE)
                on.exit(close(conn), add=TRUE)

                pb <- jmvcore:::RProtoBuf_read(jamovi.coms.AnalysisResponse, conn)
                groupPB <- pb$results$group

                oChanges <- private$.options$compProtoBuf(pb$options)
                pending <- is.character(self$options$graphicCapture) && nzchar(self$options$graphicCapture)
                resizeChanges <- grep('^results/.+/(widthScale|heightScale|width|height)$',oChanges,value=TRUE)
                presentationChanges <- c(resizeChanges,'graphicCapture','editorState','createdColumns','dataextInfo')
                private$.graphicCaptureOnly <- length(vChanges)==0L &&
                    ('graphicCapture' %in% oChanges || pending) &&
                    all(oChanges %in% presentationChanges)
                resizeOnly <- length(vChanges)==0L && length(resizeChanges)>0L &&
                    all(oChanges %in% presentationChanges)
                private$.resultsUiOnly <- resizeOnly
                private$.editorUiOnly <- resizeOnly || (length(vChanges)==0L && length(oChanges)>0L &&
                    all(oChanges %in% c('editorState','saveEditorScript','dataextInfo')))
                saving <- isTRUE(self$options$saveEditorScript) || isTRUE(self$options$saveOmvFile) ||
                    !is.null(self$options$omvFile) || isTRUE(self$options$previewDataextRequest) || private$.editorUiOnly || private$.graphicCaptureOnly
                .mzRj_restoreResults(self, groupPB, if(saving)character() else '*', pb$options)
                private$.results$fromProtoBuf(pb$results,
                    if(saving)character() else oChanges,
                    if(saving)character() else vChanges)
                # INIT saves new scales before a fresh RUN sees identical options.
                rootState<-self$results$state
                if(!is.list(rootState))rootState<-list()
                if(isTRUE(rootState$mzRjNativeResize)&&length(vChanges)==0L&&
                   all(oChanges %in% presentationChanges))private$.resultsUiOnly<-TRUE
                rootState$mzRjNativeResize<-isTRUE(private$.resultsUiOnly)
                self$results$setState(rootState)
                if(private$.resultsUiOnly) .mzRj_resizeImages(self$results,groupPB,resizeChanges)
            }

            private$.clear(vChanges)
        })
)
