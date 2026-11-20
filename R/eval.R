
eval <- function(script, data, echo, root, figWidth=400, figHeight=300, saveColumns=FALSE, dataextEnv=NULL, sourceInfo=NULL, ...) {

    # The serialized evaluator has no Analysis/self frame in System R.
    . <- function(text) {
        value<-sourceInfo$messages[[text]]
        if(is.null(value))text else value
    }
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
    eval.env$mzrjShowImage <- function(plot, width=NULL, height=NULL, name=NULL, title='')
        nativeGraphic(plot,width,height,name,title,'Image')
    eval.env$mzrjShowSvg <- function(plot, width=NULL, height=NULL, name=NULL, title='')
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
        # evaluate sees a small dispatcher; Echo must show the user's source.
        index <- suppressWarnings(as.integer(sub('.*\\(([0-9]+)L?\\).*','\\1',value$src)))
        if(length(index)==1L&&!is.na(index)&&index>=1L&&index<=length(env$expressions)) {
            env$activeIndex <- index
            value$src <- env$echoText[[index]]
        }
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

    # Keep parser references: evaluate deliberately strips them from normal input.
    # The dispatcher has its own environment, so rm(list=ls()) in user code
    # cannot remove it. Each expression is still evaluated in the same user env.
    if(is.null(sourceInfo))sourceInfo<-list()
    label<-function(value,fallback)if(is.character(value)&&length(value)==1L&&
        !is.na(value)&&nzchar(value))value else fallback
    sources<-list(
        service=list(id='<rj-service>',name=label(sourceInfo$serviceName,.('Service script')),
                     code=label(sourceInfo$serviceCode,'')),
        editor=list(id='<rj-editor>',name=label(sourceInfo$editorName,.('R editor')),code=script))
    for(key in names(sources))sources[[key]]$lines<-strsplit(sources[[key]]$code,'\n',fixed=TRUE)[[1]]
    location<-function(reference) {
        if(is.null(reference)||!inherits(reference,'srcref'))return(NULL)
        file<-attr(reference,'srcfile')$filename
        for(source in sources)if(identical(file,source$id))
            return(list(source=source,line=as.integer(reference)[1L]))
        NULL
    }
    snippet<-function(where) {
        line<-where$line;lines<-where$source$lines
        if(!is.na(line)&&line>=1L&&line<=length(lines))paste0('    ',lines[[line]]) else ''
    }
    diagnostic<-function(error,where=NULL,syntax=FALSE,calls=list()) {
        if(identical(error$code,'restart')||inherits(error,'interrupt'))return(error)
        detail<-conditionMessage(error)
        if(syntax)detail<-sub('^[^\n]*:[0-9]+:[0-9]+: *','',strsplit(detail,'\n',fixed=TRUE)[[1]][1])
        found<-Filter(Negate(is.null),lapply(calls,function(call)location(attr(call,'srcref'))))
        if(length(found)) {
            if(!is.null(where))found<-c(list(where),found)
            where<-tail(found,1)[[1]]
        }
        if(is.null(where))return(error) # Do not invent a line for external code.
        heading<-paste0(where$source$name,' — ',.('line'),' ',where$line,
                        ' — ',if(syntax).('Syntax error') else .('Error'),': ',detail)
        excerpt<-snippet(where)
        if(syntax&&!nzchar(excerpt)&&length(where$source$lines))
            excerpt<-paste0('    ',length(where$source$lines),' | ',tail(where$source$lines,1L))
        text<-c(heading,excerpt)
        seen<-paste(where$source$id,where$line)
        for(caller in rev(found)) {
            id<-paste(caller$source$id,caller$line)
            if(id %in% seen)next
            seen<-c(seen,id)
            text<-c(text,paste0(.('Called from'),' ',caller$source$name,' — ',.('line'),' ',caller$line),snippet(caller))
        }
        error$message<-paste(text[nzchar(text)],collapse='\n');error$call<-NULL
        class(error)<-unique(c('mzrj_user_error',class(error)));error
    }
    parsed<-list()
    # Validate both sources before running Service, as with the previous combined script.
    for(key in names(sources)) {
        source<-sources[[key]]
        parsed[[key]]<-tryCatch(parse(text=source$code,
            srcfile=srcfilecopy(source$id,source$lines),keep.source=TRUE),error=function(error){
                numbers<-regmatches(conditionMessage(error),regexec('^.*?:([0-9]+):([0-9]+):',conditionMessage(error)))[[1]]
                line<-if(length(numbers)>=2L)as.integer(numbers[2L]) else NA_integer_
                if(is.na(line))stop(error)
                stop(diagnostic(error,list(source=source,line=line),syntax=TRUE))
            })
    }
    dispatch<-new.env(parent=eval.env)
    dispatch$.mzrj_eval_step<-function(index)base::eval(env$expressions[[index]],envir=eval.env)
    env$echoText<-character()
    for(key in names(sources)) {
        refs<-attr(parsed[[key]],'srcref');lines<-sources[[key]]$lines;previousEnd<-0L
        for(i in seq_along(refs)) {
            ref<-as.integer(refs[[i]]);text<-as.character(refs[[i]])
            if(ref[1L]>previousEnd+1L)text<-c(lines[seq.int(previousEnd+1L,ref[1L]-1L)],text)
            tail<-substring(lines[ref[3L]],ref[6L]+1L)
            if(grepl('^\\s*#',tail))text[length(text)]<-paste0(text[length(text)],tail)
            if(i==length(refs)&&ref[3L]<length(lines))text<-c(text,lines[seq.int(ref[3L]+1L,length(lines))])
            env$echoText<-c(env$echoText,paste(text,collapse='\n'));previousEnd<-ref[3L]
        }
    }
    env$expressions<-as.expression(c(as.list(parsed$service),as.list(parsed$editor)))
    env$references<-c(attr(parsed$service,'srcref'),attr(parsed$editor,'srcref'))
    if(!length(env$expressions)&&env$echo) {
        for(source in sources)if(nzchar(trimws(source$code)))source_handler(list(src=source$code))
    }
    if(length(env$expressions)) {
        env$activeIndex<-1L;env$failure<-NULL
        captureError<-function(error) {
            if(is.null(env$failure))env$failure<-diagnostic(error,
                location(env$references[[env$activeIndex]]),calls=sys.calls())
        }
        handler$calling_handlers<-list(error=captureError)
        input<-paste0('.mzrj_eval_step(',seq_along(env$expressions),'L)',collapse='\n')
        tryCatch(evaluate::evaluate(input=input,envir=dispatch,output_handler=handler,
            stop_on_error=2),error=function(error) {
                if(identical(error$code,'restart'))stop(error)
                if(!is.null(env$failure))stop(env$failure)
                stop(diagnostic(error,location(env$references[[env$activeIndex]])))
            })
    }

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
