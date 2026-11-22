# Full Analysis save/load/acknowledgement round trip with real browser-produced PNG.
a<-commandArgs(TRUE);root<-normalizePath(a[1],winslash='/');captures<-a[2]
source(file.path(root,'tests/helper_paths.R'));mzRjTestPaths(root)
library(Rj);jmvcore:::initProtoBuf()
optionPB<-function(value){z<-RProtoBuf::new(RProtoBuf::P('jamovi.coms.AnalysisOption'));if(is.null(value))z$o<-2L else if(is.list(value)||length(value)!=1L)z$c<-optionsPB(as.list(value)) else if(is.logical(value))z$o<-if(value)1L else 0L else if(is.numeric(value))z$d<-as.double(value) else z$s<-as.character(value);z}
optionsPB<-function(values){z<-RProtoBuf::new(RProtoBuf::P('jamovi.coms.AnalysisOptions'));z$hasNames<-!is.null(names(values));if(z$hasNames)z$names<-names(values);for(value in values)z$add('options',optionPB(value));z}
for(prefix in c('Rj','Rjp'))for(mode in c('bundled','external')) {
 cls<-getFromNamespace(paste0(prefix,'Class'),'Rj');opts<-getFromNamespace(paste0(prefix,'Options'),'Rj')
 folder<-tempfile();dir.create(folder);dir.create(file.path(folder,'resources'));dir.create(file.path(folder,'temp'))
 counter<-file.path(folder,'counter');writeLines('0',counter)
 code<-paste0('writeLines(as.character(as.integer(readLines(',deparse1(counter),'))+1L),',deparse1(counter),');cat("Keep output");mzrjShowScatter(iris,"Sepal.Length","Petal.Length",name="captured",width=680,height=420,result_type="image")')
 make<-function(pb=NULL){
  z<-cls$new(options=opts$new(code=code,R=mode),data=data.frame(),datasetId='capture',analysisId=1L)
  if(is.null(pb))pb<-optionsPB(lapply(z$options$options,function(o)if(inherits(o,'OptionOutput'))list(value=TRUE,vars=list(),synced=list()) else o$value))
  z$options$fromProtoBuf(pb)
  z$.setResourcesPathSource(function(name,suffix)list(rootPath=file.path(folder,'resources'),relPath=paste0(name,'.',suffix)))
  z$.setStatePathSource(function()file.path(folder,'state'));z$init();z$.load();z$postInit();z
 }
 first<-make();stopifnot(isTRUE(first$run()),readLines(counter)=='1')
 old<-first$results$get('captured');stopifnot(inherits(old,'Html'))
 payload<-jsonlite::fromJSON(file.path(captures,if(mode=='bundled')'embedded' else 'system','iris_d3_capture.json'),simplifyVector=FALSE)
 payload$name<-NULL;payload$images[[1]]$name<-'captured';payload$images[[1]]$token<-old$state$image_capture_token
 first$.save();pb<-first$options$asProtoBuf();i<-match('graphicCapture',pb$names);stopifnot(!is.na(i))
 pb$options[[i]]<-optionPB(as.character(jsonlite::toJSON(payload,auto_unbox=TRUE)))
 second<-make(pb);stopifnot(isTRUE(second$run()),readLines(counter)=='1')
 result<-second$results$get('captured');stopifnot(inherits(result,'Image'),is.list(result$state),!is.null(result$state$mzrj_nativePng),second$options$graphicCapture=='')
 result$.createImages();second$.save();stopifnot(nzchar(result$asProtoBuf(status=3L)$image$path))
 third<-make(second$options$asProtoBuf());stopifnot(inherits(third$results$get('captured'),'Image'))
 cat(prefix,mode,': browser PNG to native Image; no script rerun; raster render and save/reload PASSED\n')
}
