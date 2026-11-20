args<-commandArgs(TRUE);root<-normalizePath(args[1],winslash='/')
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
folder<-tempfile();dir.create(folder);dir.create(file.path(folder,'resources'));dir.create(file.path(folder,'temp'))
counter<-file.path(folder,'counter');writeLines('0',counter)
code<-paste0('p<-',deparse1(counter),';writeLines(as.character(as.integer(readLines(p))+1L),p);mzrjShowSvg(function()plot(1:5),width=640,height=360,name="test_svg")')
cls<-getFromNamespace('RjClass','Rj');opts<-getFromNamespace('RjOptions','Rj')
make<-function(pb=NULL) {
 a<-cls$new(options=opts$new(code=code,vars='x',R='bundled'),data=data.frame(x=1:5),datasetId='resize',analysisId=1L)
 if(is.null(pb))pb<-optionsPB(lapply(a$options$options,function(o)if(inherits(o,'OptionOutput'))list(value=TRUE,vars=list(),synced=list()) else o$value))
 a$options$fromProtoBuf(pb)
 a$.setResourcesPathSource(function(name,suffix)list(rootPath=file.path(folder,'resources'),relPath=paste0(name,'.',suffix)))
 a$.setStatePathSource(function()file.path(folder,'state'))
 a$init();a$.load();a$postInit();a
}
a<-make();a$run();a$.save();before<-a$results$get('test_svg')$content
pb<-a$options$asProtoBuf()
for(axis in c('width','height')){
 pb$names<-c(pb$names,paste('results','test_svg',axis,sep='/'))
 pb$add('options',optionPB(if(axis=='width')810 else 450))
}
b<-make(pb);b$run()
stopifnot(readLines(counter)=='1',identical(b$results$get('test_svg')$content,before))
cat('Native Svg resize restores content without rerunning R PASSED\n')
