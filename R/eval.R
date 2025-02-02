
eval <- function(script, data, echo, root, figWidth=400, figHeight=300, saveColumns=FALSE, ...) {

    eval.env <- new.env()

    if ( ! missing(data))
        eval.env$data <- data

    origColumnNames <- colnames(eval.env$data)

    env <- new.env()
    env$count <- 1

    figWidth <- as.integer(figWidth)
    if (length(figWidth) == 1 && ! is.na(figWidth))
        env$figWidth <- figWidth
    else
        env$figWidth <- 400

    figHeight <- as.integer(figHeight)
    if (length(figHeight) == 1 && ! is.na(figHeight))
        env$figHeight <- figHeight
    else
        env$figHeight <- 300

    env$echo <- isTRUE(echo)

    createdColumns <- jmvcore::OptionOutput$new('createdColumns')
    createdColumns$value <- list(value=saveColumns, vars=character(), synced=character())
    options <- jmvcore::Options$new()
    options$.addOption(createdColumns)

    if (missing(root))
        root <- jmvcore::Group$new(options, title="Results")

    text_handler <- function(object, capture=TRUE) {

        if (inherits(object, 'ResultsElement')) {

            object$print()

        } else {

            if (inherits(object, 'shiny.tag')) {
                results <- jmvcore::Html$new(options, paste(env$count))
            } else {
                results <- jmvcore::Preformatted$new(options, paste(env$count))
            }
            
            env$count <- env$count + 1
            env$last <- NULL
            root$add(results)

            if (inherits(object, 'shiny.tag')) {
                value <- object
            } else if (is.character(object) && ! capture) {
                value <- object
            } else {
                value <- capture.output(object)
            }

            results$setContent(value)
        }

        object
    }

    source_handler <- function(value) {
        if ( ! env$echo)
            return()

        value <- trimws(value$src)
        if (value == '')
            return()

        if (is.null(env$last) || ! inherits(env$last, 'Preformatted')) {
            results <- jmvcore::Preformatted$new(options, paste(env$count))
            root$add(results)
            env$count <- env$count + 1
        }
        else {
            results <- env$last
        }

        value <- paste0('> ', value)

        content <- results$content
        if (content != '')
            content <- paste0(content, '\n', value)
        else
            content <- value

        results$setContent(content)
        env$last <- results
    }

    graphics_handler <- function(plot) {
        results <- jmvcore::Image$new(
            options=options,
            name=paste(env$count),
            renderFun='.render',
            width=env$figWidth,
            height=env$figHeight)
        root$add(results)
        results$setState(plot)
        env$count <- env$count + 1
        env$last <- NULL
    }

    handler <- evaluate::new_output_handler(
        source=source_handler,
        text=function(text) text_handler(text, FALSE),
        value=function(text) text_handler(text, TRUE),
        graphics=graphics_handler)

    # prevents a flashing window on windows
    options(device=function(...) pdf(file=NULL, ...))

    data <- evaluate::evaluate(
        input=script,
        envir=eval.env,
        output_handler=handler,
        stop_on_error=2)

    data <- eval.env$data

    output <- jmvcore::Output$new(options, 'createdColumns', initInRun=TRUE)

    if (output$enabled) {

        root$add(output)

        keys  <- character()
        names <- character()
        descs <- character()
        types <- character()

        i <- 1

        for (columnName in colnames(data)) {
            if (columnName %in% origColumnNames)
                next()
            column <- data[[columnName]]
            keys <- c(keys, as.character(i))
            names <- c(names, columnName)

            i <- i + 1

            desc <- attr(column, 'jmv-desc')
            if (is.null(desc))
                desc <- ''

            descs <- c(descs, desc)

            if (is.numeric(column))
                type <- 'continuous'
            else if (is.ordered(column))
                type <- 'ordinal'
            else
                type <- 'nominal'

            types <- c(types, type)
        }

        output$set(keys, names, descs, types)

        i <- 1
        for (name in names) {
            output$setValues(key=as.character(i), data[[name]])
            i <- i + 1
        }

        rowNums <- as.integer(rownames(data))
        if ( ! any(is.na(rowNums)))
            output$setRowNums(rowNums)
    }

    root
}

openNew <- function(data = NULL, title = "") {
    jmvReadWrite:::jmvOpn(dtaFrm = data, dtaTtl = title, rtnOut = FALSE)
}
