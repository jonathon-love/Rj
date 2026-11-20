# Run with jamovi R and the compiled candidate source directory as the argument.
args<-commandArgs(TRUE);root<-normalizePath(args[1],winslash='/')
source(file.path(root,'tests/helper_paths.R'));mzRjTestPaths(root)
library(Rj)
runner<-new.env(parent=asNamespace('Rj'))
sys.source(file.path(root,'R/mzRj_process.R'),envir=runner)
folder<-tempfile();dir.create(folder)
for(save in c(FALSE,TRUE)) {
 context<-data.frame(score=c(1.2,2.4),group=ordered(c('A','B')))
 input<-file.path(folder,'external.rds');output<-file.path(folder,'updated.rds');resultPath<-file.path(folder,'result.rds');dataPath<-file.path(folder,'dataset.rds');saveRDS(context,input);saveRDS(data.frame(x=1:5),dataPath)
 evaluatorPath<-file.path(folder,'evaluator.R')
 evaluatorEnv<-new.env(parent=asNamespace('Rj'));sys.source(file.path(root,'R/eval.R'),envir=evaluatorEnv)
 evaluator<-evaluatorEnv$eval
 writeLines(c('.mzRj_eval <-',deparse(evaluator),'.mzRj_messages <- list()', '. <- function(text)text'),evaluatorPath)
 code<-'if(Sys.getenv("MZRJ_EXPECT_NO_CONNECT")=="1")stopifnot(!requireNamespace("jmvconnect",quietly=TRUE));stopifnot(is.data.frame(dataext));dataext$score <- dataext$score*2;cat("System OMV context PASSED");plot(data$x);data$extra<-data$x*2'
 escaped<-gsub('\\','\\\\',code,fixed=TRUE);escaped<-gsub('"','\\"',escaped,fixed=TRUE)
 script<-paste(readLines(file.path(root,'inst/remote.R')),collapse='\n')
 replacements<-list(EVALUATOR=deparse1(evaluatorPath),DATAEXT_INPUT=deparse1(input),DATAEXT_OUTPUT=deparse1(output),DATA_INPUT=deparse1(dataPath),OUTPATH=gsub('\\','/',resultPath,fixed=TRUE),ECHO='TRUE',FIGWIDTH='400',FIGHEIGHT='300',COLUMNS='c("x")',SAVECOLUMNS=if(save)'TRUE'else'FALSE')
 for(key in names(replacements))script<-gsub(paste0('{{',key,'}}'),replacements[[key]],script,fixed=TRUE)
 script<-gsub('{{CODE}}',escaped,script,fixed=TRUE)
 worker<-file.path(folder,'worker.R');writeLines(script,worker)
 childEnv<-runner$.mzRj_systemREnv(as.character(getRversion()))
 if(nzchar(Sys.getenv('MZRJ_SYSTEM_TEST_LIBS')))childEnv['R_LIBS_USER']<-Sys.getenv('MZRJ_SYSTEM_TEST_LIBS')
 log<-runner$.mzRj_runProcess(mzRjSystemRscript(),c('--vanilla','--encoding=UTF-8','-'),script,env=childEnv,errorMarker='ERROR_RDS')
 stopifnot(is.null(attr(log,'status')))

 if(!file.exists(output)||!file.exists(resultPath)) {
  detail<-if(file.exists(resultPath))readRDS(resultPath)$message else paste(log,collapse='\n')
  stop(detail)
 }
 value<-readRDS(output);stopifnot(identical(value$score,context$score*2),identical(value$group,context$group))
 results<-readRDS(resultPath);stopifnot(any(vapply(results$items,function(x)inherits(x,'Image'),logical(1))))
 stopifnot(any(vapply(results$items,function(x)inherits(x,'Output'),logical(1)))==save)
 cat('Actual System R; remote template, dataext import/update/export, native plot, echo and saveColumns=',save,': PASSED (real dataset RDS round-trip; no shared-memory fixture)\n')
}

# Missing dependencies must produce one complete error record and release the runner,
# even if the worker then hangs during shutdown. Do not alter installed packages.
cat('requireNamespace <- function(package, ...) {if(package=="jmvcore")FALSE else base::requireNamespace(package,...)}\n',
 file=evaluatorPath,append=TRUE)
started<-unname(proc.time()[['elapsed']])
log<-runner$.mzRj_runProcess(mzRjSystemRscript(),c('--vanilla','--encoding=UTF-8','-'),
 paste0(script,'\nSys.sleep(60)\n'),env=childEnv,errorMarker='ERROR_RDS',timeout=10)
message<-readRDS(resultPath)$message
stopifnot(grepl('System R is missing required packages:',message,fixed=TRUE),grepl('jmvcore',message,fixed=TRUE),
 'ERROR_RDS' %in% log,is.null(attr(log,'status')),unname(proc.time()[['elapsed']])-started<8)
cat('Missing-dependency error record and hung-worker termination PASSED\n')
