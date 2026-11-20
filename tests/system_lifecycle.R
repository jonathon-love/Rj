# Actual Rj/Rjp Analysis lifecycle, real System R process and RDS dataset transport.
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
folder<-tempfile('Rj-system-lifecycle-');dir.create(folder)
e<-new.env(parent=asNamespace('Rj'))
e$system.file<-function(...,package='base',mustWork=FALSE){
 if(identical(package,'Rj')&&identical(list(...),list('remote.R')))return(file.path(root,'inst/remote.R'))
 base::system.file(...,package=package,mustWork=mustWork)
}
sys.source(file.path(root,'R/eval.R'),envir=e)
sys.source(file.path(root,'R/mzRj_process.R'),envir=e)
# Optional dependency library is confined to the test child.
if(nzchar(Sys.getenv('MZRJ_SYSTEM_TEST_LIBS'))) {
 originalEnv<-e$.mzRj_systemREnv
 e$.mzRj_systemREnv<-function(version=NULL){
  value<-originalEnv(version);value['R_LIBS_USER']<-Sys.getenv('MZRJ_SYSTEM_TEST_LIBS');value
 }
}
sys.source(file.path(root,'R/rj.b.R'),envir=e)
sys.source(file.path(root,'R/rjp.b.R'),envir=e)
rscript<-mzRjSystemRscript()
command<-if(length(args)>1L)args[2] else file.path(dirname(rscript),if(.Platform$OS.type=='windows')'R.exe' else 'R')
for(prefix in c('Rj','Rjp')) {
 base<-e[[paste0(prefix,'Class')]]
 cls<-R6::R6Class(paste0(prefix,'SystemTest'),inherit=base,private=list(.findR=function()list(path=command,rcv=as.character(getRversion()))))
 opts<-getFromNamespace(paste0(prefix,'Options'),'Rj')
 make<-function(code,mode='external',state=list()){
  sub<-tempfile(tmpdir=folder);dir.create(sub);dir.create(file.path(sub,'resources'));dir.create(file.path(sub,'temp'))
  a<-cls$new(options=opts$new(code=code,vars='x',R=mode,editorState=state),data=data.frame(x=1:5),datasetId='fixture',analysisId=1L)
  a$options$fromProtoBuf(optionsPB(lapply(a$options$options,function(o)if(inherits(o,'OptionOutput'))list(value=TRUE,vars=list(),synced=list()) else o$value)))
  a$.setResourcesPathSource(function(name,suffix)list(rootPath=file.path(sub,'resources'),relPath=paste0(name,'.',suffix)))
  a$.setStatePathSource(function()file.path(sub,'state'));a$init();a$.load();a$postInit();a
 }
 a<-make(paste(c("if(requireNamespace('cli',quietly=TRUE))loadNamespace('cli')",readLines(file.path(root,'examples/05_processx_system.R'))),collapse='\n'))
 ok<-a$run();stopifnot(isTRUE(ok),a$status!='error')
 items<-lapply(a$results$itemNames,function(n)a$results$get(n))
 stopifnot(any(vapply(items,inherits,logical(1),'Image')),any(vapply(items,inherits,logical(1),'Svg')),
           any(vapply(items,inherits,logical(1),'Output'))==identical(prefix,'Rjp'))
 # A restart must propagate through Analysis$run, then a fresh analysis can run.
 b<-make('Sys.sleep(15)');ticks<-0L
 b$.setCheckpoint(function(results){ticks<<-ticks+1L;if(ticks>=3L)'restart' else NULL})
 start<-unname(proc.time()[['elapsed']]);ok<-b$run(noThrow=TRUE)
 stopifnot(identical(ok,FALSE),ticks>=3L,unname(proc.time()[['elapsed']])-start<10)
 c<-make('cat("Recovered after restart\\n");plot(data$x)')
 stopifnot(isTRUE(c$run()),c$status!='error')
 # Both real engine paths must preserve the same multiline diagnostics.
 for(mode in c('bundled','external')) {
  cases<-list(
   list(code='x<-1\nstop("First caf\\u00e9\\nSecond line")',state=list(filename='analysis.R'),patterns=c('analysis.R','line 2','Second line')),
   list(code='x<-1\ny<- )',state=list(),patterns=c('Syntax error','line 2')),
   list(code='helper()',state=list(filename='analysis.R',serviceName='helpers.R',serviceCode='helper<-function(){\n stop("Service failure")\n}'),patterns=c('helpers.R','line 2','Called from analysis.R','line 1')))
  for(case in cases) {
   d<-make(case$code,mode,case$state)
   failure<-tryCatch(d$run(),error=identity)
   stopifnot(inherits(failure,'error'))
   for(pattern in case$patterns)stopifnot(grepl(pattern,conditionMessage(failure),fixed=TRUE))
   # Recover the SAME analysis after a reported error, not merely a fresh object.
   values<-lapply(d$options$options,function(o)if(inherits(o,'OptionOutput'))list(value=TRUE,vars=list(),synced=list()) else o$value)
   values$code<-'cat("Same analysis recovered");plot(data$x)';values$editorState<-list()
   d$options$fromProtoBuf(optionsPB(values))
   stopifnot(isTRUE(d$run()),d$status!='error')
  }
 }
 cat(prefix,': actual System R launch, native Image/Svg, Output contract, checkpoint restart and recovery PASSED (real RDS dataset transport, same-analysis error recovery)\n')
}
