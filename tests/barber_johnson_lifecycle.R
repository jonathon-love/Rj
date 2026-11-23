# Real multi-result state transitions; driven by the browser regression below.
args <- commandArgs(TRUE)
if(.Platform$OS.type=='windows')Sys.setlocale('LC_ALL','.UTF-8')
root <- args[1]; work <- args[2]; action <- args[3]; mode <- args[4]; prefix <- args[5]
dir.create(work, recursive=TRUE, showWarnings=FALSE)
source(file.path(root,'tests/helper_paths.R'));mzRjTestPaths(root)
library(Rj);jmvcore:::initProtoBuf()
optionPB <- function(value) {
    z <- RProtoBuf::new(RProtoBuf::P('jamovi.coms.AnalysisOption'))
    if(is.null(value)) z$o <- 2L else if(is.list(value)||length(value)!=1L) z$c <- optionsPB(as.list(value)) else
        if(is.logical(value)) z$o <- if(value)1L else 0L else if(is.numeric(value)) z$d <- as.double(value) else z$s <- as.character(value)
    z
}
optionsPB <- function(values) {
    z <- RProtoBuf::new(RProtoBuf::P('jamovi.coms.AnalysisOptions')); z$hasNames <- TRUE; z$names <- names(values)
    for(value in values)z$add('options',optionPB(value))
    z
}
marker <- file.path(work,'executions.txt')
stamp <- paste0('cat("run\\n",file=',deparse1(marker),',append=TRUE)\n')
source <- paste(readLines(file.path(root,'examples/10_barber_johnson.R'),encoding='UTF-8'),collapse='\n')
code <- paste0(stamp,gsub('RESULT_TYPE <- "html"','RESULT_TYPE <- "image"',source,fixed=TRUE))
opts <- getFromNamespace(paste0(prefix,'Options'),'Rj')
cls <- getFromNamespace(paste0(prefix,'Class'),'Rj')
o <- opts$new(code=code,R=mode,vars='x')
if(action=='init') {
    pb <- optionsPB(lapply(o$options,function(option)if(inherits(option,'OptionOutput'))list(value=TRUE,vars=list(),synced=list()) else option$value))
} else {
    con <- file(file.path(work,'options.pb'),'rb'); pb <- jmvcore:::RProtoBuf_read(jamovi.coms.AnalysisOptions,con); close(con)
    if(action=='capture') {
        pb$options[[match('graphicCapture',pb$names)]]$s <- paste(readLines(file.path(work,'capture.json'),warn=FALSE),collapse='\n')
    } else if(action=='resize') {
        resize <- jsonlite::fromJSON(file.path(work,'resize.json'))
        for(axis in c('width','height')) {
            key <- paste('results',resize$name,paste0(axis,'Scale'),sep='/')
            value <- resize[[axis]];index <- match(key,pb$names)
            if(is.na(index)){pb$names <- c(pb$names,key);pb$add('options',optionPB(value))} else pb$options[[index]] <- optionPB(value)
        }
    } else {
        code <- if(action=='error')paste0(stamp,'stop("Intentional recovery probe")') else
            paste0(stamp,if(action=='html')source else gsub('RESULT_TYPE <- "html"','RESULT_TYPE <- "image"',source,fixed=TRUE))
        pb$options[[match('code',pb$names)]]$s <- code
        index <- match('toggle',pb$names); pb$options[[index]]$o <- if(pb$options[[index]]$o==1L)0L else 1L
        # Deliberately retain the old capture option: explicit Run must prevail.
    }
}
o$fromProtoBuf(pb)
a <- cls$new(options=o,data=data.frame(x=1:4),datasetId='hospital',analysisId=1L)
dir.create(file.path(work,'resources'),showWarnings=FALSE)
a$.setResourcesPathSource(function(name,suffix)list(rootPath=file.path(work,'resources'),relPath=paste0(name,'.',suffix)))
a$.setStatePathSource(function()file.path(work,'state'))
a$init(); a$.load(); a$postInit()
if(action!='init') {
    # Desktop INIT publishes/saves state before a fresh RUN instance.
    # Cover that transition for capture, resize, explicit Run and recovery.
    a$serialize(final=TRUE);a$.save()
    a <- cls$new(options=o,data=data.frame(x=1:4),datasetId='hospital',analysisId=1L)
    a$.setResourcesPathSource(function(name,suffix)list(rootPath=file.path(work,'resources'),relPath=paste0(name,'.',suffix)))
    a$.setStatePathSource(function()file.path(work,'state'))
    a$init();a$.load();a$postInit()
}
failure <- tryCatch({a$run();NULL},error=identity)
if(!is.null(failure)&&action!='error')stop(failure)
if(action=='error')stopifnot(inherits(failure,'error'),grepl('Intentional recovery probe',conditionMessage(failure),fixed=TRUE))
a$.createImages();a$.save()
con <- file(file.path(work,'options.pb'),'wb'); RProtoBuf::serialize(a$options$asProtoBuf(),con); close(con)
items <- lapply(a$results$itemNames,function(n)a$results$get(n))
pending <- Filter(function(x)inherits(x,'Html')&&!is.null(x$state$image_capture_token),items)
images <- Filter(function(x)inherits(x,'Image'),items)
html <- Filter(function(x)inherits(x,'Html')&&grepl('^hospital_',x$name)&&is.null(x$state$image_capture_token),items)
response <- a$serialize(final=TRUE,includeState=TRUE)
connection <- rawConnection(response,'rb')
responsePB <- jmvcore:::RProtoBuf_read(jamovi.coms.AnalysisResponse,connection);close(connection)
responseImages <- sum(vapply(responsePB$results$group$elements,function(x)x$has('image'),logical(1)))
stopifnot(responseImages==length(images))
stateHash <- function(value) {
    file <- tempfile();writeBin(serialize(value,NULL),file)
    hash <- unname(tools::md5sum(file));unlink(file);hash
}
manifest <- list(pending=lapply(pending,function(x)list(name=x$name,content=x$content)),
    html=lapply(html,function(x)list(name=x$name,content=x$content)),
    images=vapply(images,function(x)x$name,character(1)),
    imageDetails=lapply(images,function(x){v<-x$asProtoBuf(status=3L)$image;list(name=x$name,width=v$width,height=v$height,widthM=v$widthM,heightM=v$heightM,widthB=v$widthB,heightB=v$heightB,path=v$path,stateHash=stateHash(x$state),fileHash=if(nzchar(v$path))unname(tools::md5sum(file.path(work,'resources',v$path)))else'')}),
    tableData=lapply(Filter(function(x)inherits(x,'Table'),items),function(x)list(name=x$name,hash=stateHash(x$asDF))),
    runs=length(readLines(marker)),responseBytes=length(response),responseImages=responseImages,
    tables=sum(vapply(items,function(x)inherits(x,'Table'),logical(1))),
    error=if(is.null(failure))'' else conditionMessage(failure))
writeLines(as.character(jsonlite::toJSON(manifest,auto_unbox=TRUE)),file.path(work,'manifest.json'),useBytes=TRUE)
if(length(images)) {
    grDevices::pdf(file.path(work,'native_images.pdf'),width=8,height=6)
    for(image in images)stopifnot(isTRUE(image$.render()))
    grDevices::dev.off()
}
# Reusing the same R6 instance after a capture must allow a fresh Run too.
if(action=='capture'&&length(pending)==0L) {
    current <- a$options$asProtoBuf()
    current$options[[match('code',current$names)]]$s <- paste0(stamp,source)
    index <- match('toggle',current$names);current$options[[index]]$o <- if(current$options[[index]]$o==1L)0L else 1L
    a$options$fromProtoBuf(current);a$run()
    stopifnot(inherits(a$results$get('hospital_toi_alos'),'Html'),
        is.null(a$results$get('hospital_toi_alos')$state$image_capture_token))
    # This isolated assertion must not change the persisted run marker/state.
    lines <- readLines(marker); writeLines(head(lines,-1L),marker)
}
cat(prefix,mode,action,'pending',length(pending),'Images',length(images),'runs',manifest$runs,'\n')
