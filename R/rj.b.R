
RjClass <- R6::R6Class(
    "RjClass",
    inherit = RjBase,
    active=list(
        saveColumns=function() FALSE
    ),
    private = list(
        .run = function() {

            self$results$clear()

            code <- self$options$code
            echo <- self$options$output == 'echo'
            figWidth  <- self$options$figWidth
            figHeight <- self$options$figHeight

            if (self$options$R == 'bundled') {

                eval(code, self$data, echo, self$results,
                     figWidth=figWidth, figHeight=figHeight,
                     saveColumns=self$saveColumns)

            } else {

                scriptPath <- system.file('remote.R', package='Rj', mustWork=TRUE)
                outputPath <- tempfile()

                datasetPath <- gsub('\\', '/', .datasetPath, fixed=TRUE)
                outputPath <- gsub('\\', '/', outputPath, fixed=TRUE)

                code <- gsub('\\', '\\\\', code, fixed=TRUE)
                code <- gsub('"', '\\"', code, fixed=TRUE)

                script <- readLines(scriptPath)
                script <- paste0(script, collapse='\n')
                script <- gsub('{{CODE}}', code, script, fixed=TRUE)
                script <- gsub('{{DATASET}}', datasetPath, script, fixed=TRUE)
                script <- gsub('{{OUTPATH}}', outputPath, script, fixed=TRUE)
                script <- gsub('{{FIGWIDTH}}', figWidth, script, fixed=TRUE)
                script <- gsub('{{FIGHEIGHT}}', figHeight, script, fixed=TRUE)
                script <- gsub('{{ECHO}}', echo, script, fixed=TRUE)

                columns <- self$options$get('vars')
                if (is.null(columns))
                    columns <- character()
                columns <- deparse1(columns)
                script <- gsub('{{COLUMNS}}', columns, script, fixed=TRUE)

                script <- gsub('{{SAVECOLUMNS}}', self$saveColumns, script, fixed=TRUE)

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

                    rcv <- package_version(R$rcv)

                    if (rcv > package_version('4.1.3')) {
                        libPaths=file.path(rappdirs::user_data_dir(), 'R', 'win-library', '%v')
                    } else {
                        libPaths=file.path(Sys.getenv('USERPROFILE'), 'Documents', 'R', 'win-library', '%v')
                    }

                    Sys.setenv(R_LIBS_USER=libPaths)

                    # Update cleanupCode only for "cli"
                    cleanupCode <- '
                        tryCatch({
                            try({
                                cli_dll <- getLoadedDLLs()[["cli"]]
                                if (!is.null(cli_dll)) {
                                    dyn.unload(cli_dll[["path"]])
                                }
                            }, silent=TRUE)
                        }, error=function(e) invisible(NULL))
                        '

                    script <- paste0(script, cleanupCode)

                    result <- system2(
                        command='c:\\windows\\system32\\cmd.exe',
                        args=c(
                            '/c',
                            dQuote(R$path),
                            '--no-save',
                            '--no-restore',
                            '--slave'),
                        stdout=TRUE,
                        stderr=TRUE,
                        input=script)

                } else {

                    result <- system2(
                        command=R$path,
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
                    stop("Could not find R installation in the Windows registry (HLM or HCU)")
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

                stop("Could not locate R.exe at the specified registry path")

            } else {  # For Linux and other Unix-like systems
                path <- system2('which', args = 'R', stdout = TRUE)
                if (file.exists(path))
                    return(list(path = path))
                if (file.exists('/usr/bin/R'))
                    return(list(path = '/usr/bin/R'))
                if (file.exists('/usr/local/bin/R'))
                    return(list(path = '/usr/local/bin/R'))
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
