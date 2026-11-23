# Cold namespace loading and a new empty analysis must work in the GUI locale.
args<-commandArgs(TRUE);root<-normalizePath(args[1],winslash='/')
source(file.path(root,'tests/helper_paths.R'));mzRjTestPaths(root)
library(Rj);jmvcore:::initProtoBuf()
optionPB <- function(value) {
    out <- RProtoBuf::new(RProtoBuf::P('jamovi.coms.AnalysisOption'))
    if(is.null(value))out$o<-2L else if(is.list(value) || length(value)!=1L)out$c<-optionsPB(as.list(value)) else
        if(is.logical(value))out$o<-if(value)1L else 0L else if(is.numeric(value))out$d<-as.double(value) else out$s<-as.character(value)
    out
}
optionsPB <- function(values) {
    out <- RProtoBuf::new(RProtoBuf::P('jamovi.coms.AnalysisOptions'));out$hasNames<-!is.null(names(values))
    if(out$hasNames)out$names<-names(values)
    for(value in values)out$add('options',optionPB(value))
    out
}

for(kind in c('Rj','Rjp'))for(code in c('', '\n# summary(data[1:3])\n'))for(rows in c(0L)){
 folder<-tempfile();dir.create(folder);dir.create(file.path(folder,'temp'));dir.create(file.path(folder,'resources'))
 cls<-getFromNamespace(paste0(kind,'Class'),'Rj');opts<-getFromNamespace(paste0(kind,'Options'),'Rj')
 a<-cls$new(options=opts$new(code=code),data=data.frame(row.names=seq_len(rows)),datasetId='empty',analysisId=1L)
 a$options$fromProtoBuf(optionsPB(lapply(a$options$options,function(o)if(inherits(o,'OptionOutput'))list(value=TRUE,vars=list(),synced=list()) else o$value)))
 a$.setResourcesPathSource(function(name,suffix)list(rootPath=file.path(folder,'resources'),relPath=paste0(name,'.',suffix)))
 a$.setStatePathSource(function()file.path(folder,'state'));a$init();a$.load();a$postInit()
 result<-tryCatch(a$run(),error=identity)
 stopifnot(!inherits(result,'error'),isTRUE(result),a$status!='error')
 cat(kind,rows,encodeString(code),': empty GUI startup PASSED\n')
}
