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

for(prefix in c('Rj','Rjp')) {
 cls<-getFromNamespace(paste0(prefix,'Class'),'Rj');opts<-getFromNamespace(paste0(prefix,'Options'),'Rj')
 folder<-tempfile();dir.create(folder);dir.create(file.path(folder,'temp'));dir.create(file.path(folder,'resources'))
 counter<-file.path(folder,'counter');writeLines('0',counter)
 resource<-function(name,suffix)list(rootPath=file.path(folder,'resources'),relPath=paste0(name,'.',suffix))
 statepath<-function()file.path(folder,'state')
 code<-paste0('p <- ',deparse1(counter),';writeLines(as.character(as.integer(readLines(p))+1L),p);cat("Keep text\\n");plot(data$x);data$extra<-data$x*2')
 state<-list(draft='cat("saved draft")',hasDraft=TRUE,filename='example.R',baseline='',serviceCode='',serviceName='')
 make<-function(editor=state,save=FALSE,cleared=FALSE,toggle=FALSE,script=code){
  a<-cls$new(options=opts$new(code=script,vars='x',editorState=editor,saveEditorScript=save,editorCleared=cleared,toggle=toggle),data=data.frame(x=1:5),datasetId='test',analysisId=1L)
  a$options$fromProtoBuf(optionsPB(lapply(a$options$options,function(o)if(inherits(o,"OptionOutput"))list(value=TRUE,vars=list(),synced=list()) else o$value)));a$.setResourcesPathSource(resource);a$.setStatePathSource(statepath);a$init();a$.load();a$postInit();a
 }
 a<-make();a$run()
 table<-jmvcore::Table$new(a$options,'native',columns=list(list(name='x',title='X',type='number')));table$addRow(rowKey='one',values=list(x=42));a$results$add(table)
 html<-jmvcore::Html$new(a$options,'html');html$setContent('<p>Keep HTML</p>');a$results$add(html);a$.save()
 stopifnot(readLines(counter)=='1')
 state$draft<-'cat("new draft")'
 b<-make();b$run();b$.save();stopifnot(readLines(counter)=='1',b$results$get('native')$isFilled(),b$results$get('html')$isFilled())
 c<-make(save=TRUE);c$run();c$.save();stopifnot(readLines(counter)=='1',c$results$get('native')$isFilled(),c$results$get('html')$isFilled())
 print(c$results$get('saveEditorScript')[[1]]$result)
 state$serviceCode<-'stop("Must not run")';state$serviceName<-'helpers.R'
 d<-make();d$run();d$.save();stopifnot(readLines(counter)=='1')
 e<-make(cleared=TRUE,toggle=TRUE,script='');e$run();e$.save();stopifnot(readLines(counter)=='1')
 state$serviceCode<-'helper <- function() 42'
 f<-make(toggle=FALSE,script='stopifnot(helper()==42);cat("Service PASSED")');f$run();f$.save()
 stopifnot(any(vapply(f$results$itemNames,function(n){z<-f$results$get(n);inherits(z,'Preformatted')&&grepl('Service PASSED',z$content)},logical(1))))
 cat(prefix,': draft/Load/Service/Save do not execute code; Clear skips Service; Table/Html retained; explicit Run with Service PASSED\n')
}
