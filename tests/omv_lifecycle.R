# Run with jamovi R and the compiled candidate source directory as the argument.
args<-commandArgs(TRUE);root<-normalizePath(args[1],winslash='/')
source(file.path(root,'tests/helper_paths.R'));mzRjTestPaths(root)
library(Rj);jmvcore:::initProtoBuf()
optionPB<-function(value) {
 z<-RProtoBuf::new(RProtoBuf::P('jamovi.coms.AnalysisOption'))
 if(is.null(value))z$o<-2L else if(is.list(value)||length(value)!=1L)z$c<-optionsPB(as.list(value)) else
 if(is.logical(value))z$o<-if(value)1L else 0L else if(is.numeric(value))z$d<-as.double(value) else z$s<-as.character(value)
 z
}
optionsPB<-function(values) {
 z<-RProtoBuf::new(RProtoBuf::P('jamovi.coms.AnalysisOptions'));z$hasNames<-!is.null(names(values));if(z$hasNames)z$names<-names(values)
 for(value in values)z$add('options',optionPB(value));z
}

for(prefix in c('Rj','Rjp'))for(mode in c('bundled','external')) {
 cls<-getFromNamespace(paste0(prefix,'Class'),'Rj');opts<-getFromNamespace(paste0(prefix,'Options'),'Rj')
 folder<-tempfile();dir.create(folder);dir.create(file.path(folder,'resources'));dir.create(file.path(folder,'temp'))
 resource<-function(name,suffix)list(rootPath=file.path(folder,'resources'),relPath=paste0(name,'.',suffix))
 statepath<-function()file.path(folder,'state')
 input<-data.frame(x=1:5);external<-data.frame(score=c(1.2,NA,3.4),group=ordered(c('Low','High','Low'),levels=c('Low','High')))
 attr(external$score,'jmv-desc')<-'Score description'
 source<-file.path(folder,'input.omv');jmvReadWrite::write_omv(external,source)
 make<-function(file=NULL,preview=FALSE,request=FALSE,save=FALSE,code='stop("This action must not run editor code")',R=mode,toggle=FALSE){
  a<-cls$new(options=opts$new(code=code,vars='x',R=R,omvFile=file,previewDataext=preview,previewDataextRequest=request,saveOmvFile=save,toggle=toggle),data=input,datasetId='omv',analysisId=1L)
  a$options$fromProtoBuf(optionsPB(lapply(a$options$options,function(o)if(inherits(o,'OptionOutput'))list(value=TRUE,vars=list(),synced=list()) else o$value)))
  a$.setResourcesPathSource(resource);a$.setStatePathSource(statepath);a$init();a$.load();a$postInit();a
 }
 a<-make(R='bundled',code='cat("Keep this text");plot(data$x)');a$run();a$.save()
 b<-make(file=list(path=source,filename='input.omv'));b$run();b$.save()
 path<-getFromNamespace('.mzRj_omvPath','Rj')(b);hash<-unname(tools::md5sum(paste0(path,'.rds')))
 text<-function(a)any(vapply(a$results$itemNames,function(n){x<-a$results$get(n);inherits(x,'Preformatted')&&grepl('Keep this text',x$content)},logical(1)))
 stopifnot(is.null(b$options$omvFile),text(b),isTRUE(all.equal(b$data,input,check.attributes=FALSE)))
 c<-make(preview=TRUE,request=TRUE);c$run();c$.save()
 stopifnot(c$results$get('dataextPreview')$visible,!c$options$previewDataextRequest,text(c),hash==unname(tools::md5sum(paste0(path,'.rds'))))
 d<-make(preview=TRUE,save=TRUE);d$run();d$.save()
 stopifnot(d$results$get('saveOmvFile')[[1]]$result$filename=='dataext.omv',text(d))
 roundtrip<-jmvReadWrite::read_omv(paste0(path,'.omv'))
 stopifnot(isTRUE(all.equal(as.numeric(roundtrip$score),as.numeric(external$score))),identical(as.character(roundtrip$group),as.character(external$group)),attr(roundtrip$score,'jmv-desc')=='Score description')
 bad<-file.path(folder,'invalid.omv');writeLines('not an OMV',bad)
 e<-make(file=list(path=bad,filename='invalid.omv'));try(e$run(),silent=TRUE);e$.save()
 stopifnot(is.null(e$options$omvFile),hash==unname(tools::md5sum(paste0(path,'.rds'))))
 f<-make(R='bundled',toggle=TRUE,code='dataext$score <- dataext$score*2;cat("Transformed")');f$run();f$.save()
 transformed<-getFromNamespace('.mzRj_dataext','Rj')(f)
 stopifnot(isTRUE(all.equal(as.numeric(transformed$score),as.numeric(external$score)*2)),isTRUE(all.equal(f$data,input,check.attributes=FALSE)))
 old<-getFromNamespace('.mzRj_omvPath','Rj')(f)
 g<-make(R='bundled',code='dataext <- 42');try(g$run(),silent=TRUE)
 stopifnot(identical(getFromNamespace('.mzRj_omvPath','Rj')(g),old))
 cat(prefix,mode,': Read/preview/Save without executing editor; data/metadata round-trip; current data unchanged; read/Run failures retain cache PASSED\n')
}
