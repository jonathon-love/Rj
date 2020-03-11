
RjClass <- R6::R6Class(
    "RjClass",
    inherit = RjBase,
    private = list(
        .run = function() {

            self$results$clear()

            code <- self$options$code
            echo <- self$options$output == 'echo'
            figWidth  <- self$options$figWidth
            figHeight <- self$options$figHeight

            if (self$options$R == 'bundled') {

                eval(code, self$data, echo, self$results,
                     figWidth=figWidth, figHeight=figHeight)

            } else {

                scriptPath <- system.file('remote.R', package='Rj', mustWork=TRUE)
                outputPath <- tempfile()

                datasetPath <- gsub('\\', '/', .datasetPath, fixed=TRUE)
                outputPath <- gsub('\\', '/', outputPath, fixed=TRUE)

                code <- gsub('\\', '\\\\', code, fixed=TRUE)
                code <- gsub('"', '\\"', code, fixed=TRUE)

                script <- readLines(scriptPath)
                script <- paste0(script, collapse='\n')
                script <- sub('{{CODE}}', code, script, fixed=TRUE)
                script <- sub('{{DATASET}}', datasetPath, script, fixed=TRUE)
                script <- sub('{{OUTPATH}}', outputPath, script, fixed=TRUE)
                script <- sub('{{FIGWIDTH}}', figWidth, script, fixed=TRUE)
                script <- sub('{{FIGHEIGHT}}', figHeight, script, fixed=TRUE)
                script <- sub('{{ECHO}}', echo, script, fixed=TRUE)

                R <- private$.findR()

                Sys.unsetenv(c(
                    'R_ENVIRON',
                    'R_PROFILE',
                    'R_PROFILE_USER',
                    'R_ENVIRON_USER',
                    'R_LIBS_SITE',
                    'R_LIBS_USER',
                    'R_LIBS',
                    'R_USER',
                    'HOME'));

                if (Sys.info()['sysname'] == 'Windows') {

                    Sys.setenv(R_LIBS_USER='~/R/win-library/%v')

                    result <- system2(
                        command='c:\\windows\\system32\\cmd.exe',
                        args=c(
                            '/c',
                            dQuote(R),
                            '--no-save',
                            '--no-restore',
                            '--slave'),
                        stdout=TRUE,
                        stderr=TRUE,
                        input=script)

                } else {

                    result <- system2(
                        command=R,
                        args=c(
                            '--no-save',
                            '--no-restore',
                            '--slave'),
                        stdout=TRUE,
                        stderr=TRUE,
                        input=script)
                }

                for (line in result) {
                    if (jmvcore::startsWith(line, 'ERROR: ')) {

                        message <- substring(line, 8)
                        if (message == 'Memory segment version is too new')
                            message <- 'A newer version of jmvconnect is required'
                        if (message == 'Memory segment version is too old')
                            message <- 'A newer version of jamovi is required'
                        stop(message, call.=FALSE)

                    } else if (line == 'OK') {
                        results <- readRDS(file=outputPath)
                        for (item in results$items)
                            self$results$add(item)
                    }
                }

                unlink(outputPath)

                # options <- jmvcore::Options$new();
                # text <- jmvcore::Preformatted$new(options, 'output');
                # self$results$add(text)
                #
                # text$setContent(result)
            }

        },
        .render=function(image, ...) {
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
        .findR=function() {

            os <- Sys.info()[['sysname']]

            if (os == 'Darwin') {
                version <- Sys.readlink('/Library/Frameworks/R.framework/Versions/Current')
                path <- file.path('/Library/Frameworks/R.framework/Versions', version)
                path <- file.path(path, 'Resources', 'bin', 'R')

                if (file.exists(path))
                    return(path)
                if (file.exists('/usr/bin/R'))
                    return('/usr/bin/R')
                if (file.exists('/usr/local/bin/R'))
                    return('/usr/local/bin/R')
                if (file.exists('/opt/local/bin/R'))
                    return('/opt/local/bin/R')

            } else if (os == 'Windows') {

                entries <- try(readRegistry('Software\\R-core\\R', 'HLM'))
                if (inherits(entries, 'try-error'))
                    stop('Could not find system R (no appropriate registry entries)')
                home <- entries$InstallPath
                path <- file.path(home, 'bin', 'x64', 'R.exe')
                if (file.exists(path))
                    return(path)
                stop('Could not find system R (registry entries are incorrect)')

            } else {
                path <- system2('which', args='R', stdout=TRUE)
                if (file.exists(path))
                    return(path)
                if (file.exists('/usr/bin/R'))
                    return('/usr/bin/R')
                if (file.exists('/usr/local/bin/R'))
                    return('/usr/local/bin/R')
            }

            stop('Could not find system R')
        }),
    public=list(
        asSource=function() {
            if ( ! self$options$output == 'echo')
                return(self$options$code)
            else
                return('')
        },
        .load=function(vChanges=character()) {

            jmvcore:::initProtoBuf()

            path <- private$.statePathSource()
            Encoding(path) <- 'UTF-8'

            if (base::file.exists(path)) {
                conn <- file(path, open="rb", raw=TRUE)
                on.exit(close(conn), add=TRUE)

                pb <- jmvcore:::RProtoBuf_read(jamovi.coms.AnalysisResponse, conn)
                groupPB <- pb$results$group

                for (itemPB in groupPB$elements) {
                    if (itemPB$has('preformatted')) {
                        self$results$add(jmvcore::Preformatted$new(
                            self$options,
                            name=itemPB$name,
                            title=itemPB$title))
                    } else if (itemPB$has('image')) {
                        self$results$add(jmvcore::Image$new(
                            self$options,
                            name=itemPB$name,
                            title=itemPB$title,
                            renderFun='.render',
                            width=itemPB$image$width,
                            height=itemPB$image$height))
                    }
                }

                oChanges <- private$.options$compProtoBuf(pb$options)
                private$.results$fromProtoBuf(pb$results, oChanges, vChanges)
            }

            private$.clear(vChanges)
        })
)
