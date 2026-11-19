
eval <- function(script, data, echo, root, figWidth=400, figHeight=300, saveColumns=FALSE, dataextEnv=NULL, ...) {

    eval.env <- new.env()
    eval.env$dataext <- if(is.null(dataextEnv)) data.frame() else dataextEnv$data

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

    # These closures are serialized with the evaluator for System R as well.
    nativeGraphic <- function(plot, width=NULL, height=NULL, name=NULL, title='', type='Image') {
        if (!is.function(plot)) stop(.('The plot argument must be a function with no arguments.'),call.=FALSE)
        dimension <- function(value) {
            if(is.null(value)) return(NULL)
            if(!is.numeric(value) || length(value)!=1L || !is.finite(value) ||
               value!=floor(value) || value<1 || value>10000)
                stop(.('Figure dimensions must be whole numbers from 1 to 10000 pixels.'),call.=FALSE)
            as.integer(value)
        }
        width<-dimension(width);height<-dimension(height)
        ratio<-env$figWidth/env$figHeight
        if(is.null(width) && is.null(height)) {
            width<-env$figWidth;height<-env$figHeight
        } else if(is.null(width)) width<-max(1L,round(height*ratio))
        else if(is.null(height)) height<-max(1L,round(width/ratio))
        if(is.null(name)) { name<-paste(env$count);env$count<-env$count+1L }
        if(!is.character(name) || length(name)!=1L || !grepl('^[A-Za-z0-9_]+$',name) ||
           !is.null(root$get(name))) stop(.('Use a unique result name containing letters, digits or underscores.'),call.=FALSE)
        if(!is.character(title) || length(title)!=1L || is.na(title))
            stop(.('The figure title must be a single string.'),call.=FALSE)
        path<-tempfile(fileext='.svg')
        on.exit(unlink(path),add=TRUE)
        if(type=='Svg') grDevices::svg(path,width=width/96,height=height/96)
        else {
            grDevices::pdf(NULL,width=width/96,height=height/96)
            grDevices::dev.control(displaylist='enable')
        }
        device<-grDevices::dev.cur()
        on.exit(if(device %in% grDevices::dev.list())grDevices::dev.off(device),add=TRUE)
        plot()
        if(type=='Image') state<-grDevices::recordPlot()
        grDevices::dev.off(device)
        if(type=='Image') {
            item<-jmvcore::Image$new(options,name=name,title=title,renderFun='.render',width=width,height=height)
            item$setState(state)
        } else {
            markup<-paste(readLines(path,warn=FALSE,encoding='UTF-8'),collapse='\n')
            markup<-sub('<\\?xml[^>]*\\?>','',markup)
            markup<-sub('<svg ',paste0('<svg class="jmv-results-svg-content jmv-results-svg-selection" '),markup,fixed=TRUE)
            markup<-sub('width="[^"]*"',paste0('width="',width,'"'),markup)
            markup<-sub('height="[^"]*"',paste0('height="',height,'"'),markup)
            item<-jmvcore::Svg$new(options,name=name,title=title,content=markup)
        }
        root$add(item)
        invisible(NULL)
    }
    eval.env$rjShowImage <- function(plot, width=NULL, height=NULL, name=NULL, title='')
        nativeGraphic(plot,width,height,name,title,'Image')
    eval.env$rjShowSvg <- function(plot, width=NULL, height=NULL, name=NULL, title='')
        nativeGraphic(plot,width,height,name,title,'Svg')

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

    if(!is.null(dataextEnv))dataextEnv$data <- eval.env$dataext
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
