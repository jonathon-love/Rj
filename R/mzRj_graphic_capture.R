# The client captures a PNG; this command replaces its own pending Html only.
# It must never execute Python or invalidate unrelated Results/Output/dataext.
.mzRj_clearGraphicCapture <- function(self) {
    pb <- self$options$asProtoBuf()
    if (is.null(pb)) return(invisible(NULL))
    index <- match('graphicCapture', pb$names)
    if (!is.na(index)) {
        pb$options[[index]]$s <- ''
        self$options$fromProtoBuf(pb)
    }
    invisible(NULL)
}

.mzRj_capturePng <- function(value) {
    scalar <- function(x) is.numeric(x) && length(x)==1L && is.finite(x) &&
        x==trunc(x) && x>=1L && x<=2000L
    if (!is.list(value) || !scalar(value$width) || !scalar(value$height) ||
        !is.character(value$content) || length(value$content)!=1L ||
        nchar(value$content, type='bytes')>1000000L ||
        nchar(value$content)%%4L!=0L ||
        !grepl('^[A-Za-z0-9+/]+={0,2}$',value$content))
        stop('Invalid native Image capture.',call.=FALSE)
    bytes <- jsonlite::base64_dec(value$content)
    signature <- as.raw(c(137,80,78,71,13,10,26,10))
    if (length(bytes)<33L || !identical(bytes[1:8],signature) ||
        !identical(rawToChar(bytes[13:16]),'IHDR'))
        stop('Native Image capture is not a PNG.',call.=FALSE)
    dims <- readBin(bytes[17:24],what='integer',n=2L,size=4L,endian='big')
    if (length(dims)!=2L || anyNA(dims) || any(dims<1L | dims>4000L) ||
        prod(as.double(dims))>4000000)
        stop('Native Image capture exceeds the supported dimensions.',call.=FALSE)
    # Decode before modifying Results; the same decoder is used by .render.
    png::readPNG(bytes)
    value
}

.mzRj_captureTitle <- function(old) {
    title <- old$state$image_capture_title
    if (is.character(title) && length(title)==1L && !is.na(title)) title else old$title
}

# A failed pending result regains its original heading and remains retryable.
.mzRj_captureError <- function(self, old, content) {
    error <- jmvcore::Html$new(self$options,name=old$name,title=.mzRj_captureTitle(old))
    error$setState(old$state)
    error$setContent(content)
    self$results$add(error)
    invisible(error)
}

.mzRj_applyGraphicCapture <- function(self) {
    text <- self$options$graphicCapture
    if (!is.character(text) || length(text)!=1L || !nzchar(text) ||
        nchar(text,type='bytes')>1500000L) return(invisible(character()))
    payload <- tryCatch(jsonlite::fromJSON(text,simplifyVector=FALSE),error=function(e)NULL)
    if (!is.list(payload) || !identical(payload$version,1L) ||
        !is.list(payload$images) || length(payload$images)>20L)
        return(invisible(character()))
    replaced <- list()
    for (value in payload$images) {
        if (!is.list(value) || !is.character(value$name) || length(value$name)!=1L ||
            !is.character(value$token) || length(value$token)!=1L ||
            !grepl('^[a-f0-9]{32}$',value$token)) next
        old <- self$results$get(value$name)
        if (is.null(old) || !inherits(old,'Html')) next
        state <- old$state
        # A token is bound to a single pending result of the current execution.
        if (!is.list(state) || !identical(state$image_capture_token,value$token)) next
        capture <- tryCatch(.mzRj_capturePng(value),error=function(e)NULL)
        if (is.null(capture)) {
            .mzRj_captureError(self,old,'<p>Native Image preparation failed. Reduce the figure size and run again.</p>')
            next
        }
        image <- jmvcore::Image$new(self$options,name=value$name,title=.mzRj_captureTitle(old),
            renderFun='.render',width=as.integer(capture$width),height=as.integer(capture$height))
        image$setState(list(mzrj_nativePng=capture$content))
        replaced[[value$name]] <- old
        self$results$add(image)
    }
    invisible(names(replaced))
}
