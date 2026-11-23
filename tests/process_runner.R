# Real System R process tests. Arguments: source root, optional System R executable.
args<-commandArgs(TRUE);root<-normalizePath(args[1],winslash='/')
source(file.path(root,'tests/helper_paths.R'));mzRjTestPaths(root)
library(Rj)
e<-new.env(parent=asNamespace('Rj'));sys.source(file.path(root,'R/mzRj_process.R'),envir=e)
rscript<-mzRjSystemRscript()
command<-if(length(args)>1L)args[2] else file.path(dirname(rscript),if(.Platform$OS.type=='windows')'R.exe' else 'R')
stopifnot(file.exists(command),file.exists(rscript))
checks<-0L
check<-function(...){stopifnot(...);checks<<-checks+1L}
run<-function(script,env=e$.mzRj_systemREnv(as.character(getRversion())),...)e$.mzRj_runProcess(command,c('--no-save','--no-restore','--slave','--encoding=UTF-8'),script,env=env,...)
x<-run('cat("hello\n");flush(stdout());cat("stderr\n",file=stderr());cat("tail")')
check(is.null(attr(x,'status')),all(c('hello','stderr','tail') %in% x))
x<-run('cat("\u00e8 \u03b1 \u65e5\n")')
check(any(vapply(x,function(line)identical(utf8ToInt(line),c(232L,32L,945L,32L,26085L)),logical(1))))
x<-run('cat(strrep("x",1500000),"\nOK\n",sep="")')
check(any(nchar(x,type='bytes')==1500000L),tail(x,1L)=='OK')
x<-run('cat("failure\n");quit(save="no",status=7L)')
check(identical(attr(x,'status'),7L),'failure' %in% x)
x<-run('Sys.sleep(10)',timeout=0.4)
check(identical(attr(x,'status'),124L))
ticks<-0L
run('Sys.sleep(0.7)',checkpoint=function()ticks<<-ticks+1L)
check(ticks>=2L,ticks<40L)
restart<-jmvcore::createError('restarting','restart')
start<-unname(proc.time()[['elapsed']])
failure<-tryCatch(run('Sys.sleep(10)',checkpoint=function(){if(unname(proc.time()[['elapsed']])-start>0.3)stop(restart)}),error=identity)
check(identical(failure,restart))
check('recovered' %in% run('cat("recovered\n")'))
# Overrides apply only to the child; NA removes a variable and leaves the parent intact.
key<-'MZRJ_PROCESS_TEST_ENV';previous<-Sys.getenv(key,unset=NA_character_)
Sys.setenv(MZRJ_PROCESS_TEST_ENV='parent')
x<-run('cat(Sys.getenv("MZRJ_PROCESS_TEST_ENV",unset="absent"),"\n",sep="")',env=c(MZRJ_PROCESS_TEST_ENV=NA_character_))
check('absent' %in% x,Sys.getenv(key)=='parent')
if(is.na(previous))Sys.unsetenv(key) else Sys.setenv(MZRJ_PROCESS_TEST_ENV=previous)
before<-Sys.getenv(c('HOME','R_HOME','R_USER','R_LIBS_USER'),unset=NA_character_)
childEnv<-e$.mzRj_systemREnv(as.character(getRversion()))
run('cat("environment ready\n")',env=childEnv)
check(identical(before,Sys.getenv(names(before),unset=NA_character_)))
# A child remains owned even if the original System R parent exits normally.
for(mode in c('success','timeout','restart')) {
 folder<-tempfile('Rj process with spaces ');dir.create(folder)
 pidFile<-file.path(folder,'child.pid');worker<-file.path(folder,'child worker.R')
 writeLines(paste0('writeLines(as.character(Sys.getpid()),',deparse1(pidFile),');Sys.sleep(60)'),worker)
 script<-paste0('system2(',deparse1(rscript),',c("--vanilla",shQuote(',deparse1(worker),')),wait=FALSE,stdout=FALSE,stderr=FALSE);',
   'while(!file.exists(',deparse1(pidFile),'))Sys.sleep(0.02);',if(mode=='success')'cat("done\n")' else 'Sys.sleep(60)')
 child<-NULL
 callback<-function(){
   if(is.null(child)&&file.exists(pidFile))child<<-ps::ps_handle(as.integer(readLines(pidFile,warn=FALSE)[1]))
   if(mode=='restart'&&!is.null(child))stop(restart)
 }
 value<-tryCatch(run(script,checkpoint=callback,timeout=if(mode=='timeout')5 else 15),error=identity)
 check(!is.null(child))
 alive<-function()tryCatch(ps::ps_is_running(child)&&ps::ps_status(child)!='zombie',error=function(e)FALSE)
 deadline<-unname(proc.time()[['elapsed']])+3
 while(alive()&&unname(proc.time()[['elapsed']])<deadline)Sys.sleep(0.05)
 running<-alive();if(running)try(ps::ps_kill(child),silent=TRUE)
 check(!running)
 if(mode=='timeout')check(identical(attr(value,'status'),124L))
 if(mode=='restart')check(identical(value,restart))
 unlink(folder,recursive=TRUE)
}
# A reported worker error must not keep the UI waiting for a hung R finalizer.
start<-unname(proc.time()[['elapsed']])
x<-run('cat("ERROR_RDS\\n");flush(stdout());Sys.sleep(60)',errorMarker='ERROR_RDS')
check('ERROR_RDS' %in% x,is.null(attr(x,'status')),unname(proc.time()[['elapsed']])-start<5)
check('after reported error' %in% run('cat("after reported error\\n")'))
cat('System R processx runner:',checks,'checks PASSED\n')
