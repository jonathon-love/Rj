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
for(prefix in c('Rj','Rjp'))for(engine in c('embedded','system')) {
 cls<-getFromNamespace(paste0(prefix,'Class'),'Rj');opts<-getFromNamespace(paste0(prefix,'Options'),'Rj')
 folder<-tempfile();dir.create(folder);dir.create(file.path(folder,'resources'));dir.create(file.path(folder,'temp'))
 resource<-function(name,suffix)list(rootPath=file.path(folder,'resources'),relPath=paste0(name,'.',suffix))
 statepath<-function()file.path(folder,'state')
 counter<-file.path(folder,'counter');writeLines('0',counter)
 code<-paste0('p <- ',deparse1(counter),';writeLines(as.character(as.integer(readLines(p))+1L),p);cat("Keep text\\n");plot(data$x);plot(data$x^2);data$extra<-data$x*2')
 make<-function(pb=NULL) {
  a<-cls$new(options=opts$new(code=code,vars='x',R=if(engine=='embedded')'bundled' else 'external'),data=data.frame(x=1:5),datasetId='resize',analysisId=1L)
  if(is.null(pb))pb<-optionsPB(lapply(a$options$options,function(o)if(inherits(o,'OptionOutput'))list(value=TRUE,vars=list(),synced=list()) else o$value))
  a$options$fromProtoBuf(pb);a$.setResourcesPathSource(resource);a$.setStatePathSource(statepath);a$init();a$.load();a$postInit();a
 }
 a<-make()
 if(engine=='embedded')a$run() else {
  # Capture in an actual System R process using its installed jmvconnect evaluator.
  input<-file.path(folder,'input.rds');output<-file.path(folder,'system.rds');saveRDS(list(code=code,data=data.frame(x=1:5),save=prefix=='Rjp'),input)
  worker<-file.path(folder,'worker.R');writeLines(c('args<-commandArgs(TRUE);x<-readRDS(args[1]);z<-jmvconnect:::eval(x$code,x$data,FALSE,saveColumns=x$save);saveRDS(z,args[2])'),worker)
  status<-system2(mzRjSystemRscript(),c('--vanilla',shQuote(worker),shQuote(input),shQuote(output)),stdout=TRUE,stderr=TRUE)
  if(!file.exists(output))stop(paste(status,collapse='\n'))
  result<-readRDS(output);for(item in result$items)a$results$add(item)
  getFromNamespace('.mzRj_bindImages','Rj')(a)
 }
 images<-Filter(function(n)inherits(a$results$get(n),'Image'),a$results$itemNames);stopifnot(length(images)==2L)
 first<-images[[1]];second<-images[[2]]
 stopifnot(identical(a$results$get(first)$options,a$options),readLines(counter)=='1')
 a$results$get(first)$.createImages();a$.save()
 for(scale in list(c(1.5,.75),c(2,1.5),c(1,1))) {
  pb<-a$options$asProtoBuf()
  for(axis in c('width','height')) {
   key<-paste('results',first,paste0(axis,'Scale'),sep='/');i<-match(key,pb$names);value<-scale[if(axis=='width')1 else 2]
   if(is.na(i)){pb$names<-c(pb$names,key);pb$add('options',optionPB(value))}else pb$options[[i]]<-optionPB(value)
  }
  b<-make(pb);b$run()
  image<-b$results$get(first);expected<-list(width=as.integer(400*scale[1]),height=as.integer(300*scale[2]))
  stopifnot(identical(image$size,expected),identical(b$results$get(second)$size,list(width=400L,height=300L)),readLines(counter)=='1',!is.null(image$state))
  image$.createImages();b$.save()
  saved<-image$asProtoBuf(status=3L)$image
  stopifnot(saved$width==expected$width,saved$height==expected$height,saved$widthM==400,saved$heightM==300,nzchar(saved$path))
  c<-make(b$options$asProtoBuf());stopifnot(identical(c$results$get(first)$size,expected))
  a<-b
 }
 cat(prefix,engine,': two native plots; independent repeated resize; raster regenerated; save/load dimensions retained; script counter unchanged PASSED\n')
}
