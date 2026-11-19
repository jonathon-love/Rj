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

folder<-tempfile();dir.create(folder)
for(save in c(FALSE,TRUE)) {
 context<-data.frame(score=c(1.2,2.4),group=ordered(c('A','B')))
 input<-file.path(folder,'external.rds');output<-file.path(folder,'updated.rds');resultPath<-file.path(folder,'result.rds');dataPath<-file.path(folder,'dataset.rds');saveRDS(context,input);saveRDS(data.frame(x=1:5),dataPath)
 evaluatorPath<-file.path(folder,'evaluator.R')
 evaluator<-getFromNamespace('eval','Rj')
 writeLines(c('.mzRj_eval <-',deparse(evaluator),'.mzRj_messages <- list()', '. <- function(text)text'),evaluatorPath)
 code<-'stopifnot(is.data.frame(dataext));dataext$score <- dataext$score*2;cat("System OMV context PASSED");plot(data$x);data$extra<-data$x*2'
 escaped<-gsub('\\','\\\\',code,fixed=TRUE);escaped<-gsub('"','\\"',escaped,fixed=TRUE)
 script<-paste(readLines(system.file('remote.R',package='Rj')),collapse='\n')
 replacements<-list(EVALUATOR=deparse1(evaluatorPath),DATAEXT_INPUT=deparse1(input),DATAEXT_OUTPUT=deparse1(output),DATASET='fixture',OUTPATH=gsub('\\','/',resultPath,fixed=TRUE),ECHO='TRUE',FIGWIDTH='400',FIGHEIGHT='300',COLUMNS='c("x")',SAVECOLUMNS=if(save)'TRUE'else'FALSE')
 for(key in names(replacements))script<-gsub(paste0('{{',key,'}}'),replacements[[key]],script,fixed=TRUE)
 script<-gsub('{{CODE}}',escaped,script,fixed=TRUE)
 # Only the live shared-memory dataset acquisition is replaced by a fixture.
 script<-gsub("remoteEnvironment <- new.env(parent=asNamespace('jmvconnect'))",paste0("remoteEnvironment <- new.env(parent=asNamespace('jmvconnect'))\nremoteEnvironment$readDF <- function(...)readRDS(",deparse1(dataPath),")"),script,fixed=TRUE)
 worker<-file.path(folder,'worker.R');writeLines(script,worker)
 log<-system2(mzRjSystemRscript(),c('--vanilla',shQuote(worker)),stdout=TRUE,stderr=TRUE)
 if(!file.exists(output)||!file.exists(resultPath))stop(paste(log,collapse='\n'))
 value<-readRDS(output);stopifnot(identical(value$score,context$score*2),identical(value$group,context$group))
 results<-readRDS(resultPath);stopifnot(any(vapply(results$items,function(x)inherits(x,'Image'),logical(1))))
 stopifnot(any(vapply(results$items,function(x)inherits(x,'Output'),logical(1)))==save)
 cat('Actual System R; remote template, dataext import/update/export, native plot, echo and saveColumns=',save,': PASSED (dataset acquisition fixture; desktop shared-memory test pending)\n')
}
