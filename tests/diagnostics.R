# Source-aware syntax/runtime diagnostics and evaluation semantics, without a GUI.
args<-commandArgs(TRUE);root<-normalizePath(args[1],winslash='/')
source(file.path(root,'tests/helper_paths.R'));mzRjTestPaths(root)
library(Rj)
e<-new.env(parent=asNamespace('Rj'));sys.source(file.path(root,'R/eval.R'),e)
run<-function(code,echo=FALSE,sourceInfo=NULL)e$eval(code,data.frame(x=1:5),echo,sourceInfo=sourceInfo)
failure<-function(code,sourceInfo=NULL)tryCatch(run(code,sourceInfo=sourceInfo),error=identity)
check<-function(value,patterns){stopifnot(inherits(value,'error'));text<-conditionMessage(value);for(pattern in patterns)stopifnot(grepl(pattern,text,fixed=TRUE));stopifnot(!grepl('.mzrj_eval_step',text,fixed=TRUE));text}
check(failure('x<-1\ny<- )'),c('R editor','line 2','Syntax error','y<- )'))
check(failure('x<-1\nstop("First caf\\u00e9\\nSecond line")'),c('line 2','First caf','Second line','stop('))
check(failure('f<-function(){\n stop("Nested")\n}\nf()'),c('line 2','Called from R editor','line 4','f()'))
info<-list(serviceName='helpers.R',serviceCode='helper<-function(){\n stop("Service function")\n}',editorName='analysis.R')
check(failure('helper()',info),c('helpers.R','line 2','Called from analysis.R','line 1'))
check(failure('plot(data$x)',list(serviceName='helpers.R',serviceCode='x<-1\nstop("Service execution")')),c('helpers.R','line 2','Service execution'))
# Parsing the editor must finish before any Service side effect occurs.
marker<-tempfile();info<-list(serviceCode=paste0('writeLines("executed",',deparse1(marker),')'))
check(failure('bad <- )',info),c('Syntax error'));stopifnot(!file.exists(marker))
# Do not replace a handled error with a stale diagnostic.
check(failure('tryCatch(stop("handled"),error=function(e)NULL)\nstop("real")'),c('line 2','real'))
# Service shares variables and the graphics device with the editor.
z<-run('abline(h=3);cat(shared);mzrjShowSvg(function()plot(1:5),name="vector")',sourceInfo=list(serviceCode='shared<-42;plot(data$x)'))
items<-lapply(z$itemNames,function(n)z$get(n));stopifnot(any(vapply(items,inherits,logical(1),'Image')),inherits(z$get('vector'),'Svg'))
# User cleanup cannot delete the dispatcher; automatic printing and Echo remain.
z<-run('# Initial comment\n1+1 # Inline comment\n2+2\nrm(list=ls())\ncat("After cleanup")\n# Final comment',echo=TRUE)
texts<-vapply(z$itemNames,function(n){item<-z$get(n);if(inherits(item,'Preformatted'))item$content else ''},character(1))
text<-paste(texts,collapse='\n');stopifnot(grepl('[1] 2',text,fixed=TRUE),grepl('[1] 4',text,fixed=TRUE),grepl('After cleanup',text,fixed=TRUE),!grepl('.mzrj_eval_step',text,fixed=TRUE))
stopifnot(grepl('# Initial comment',text,fixed=TRUE),grepl('# Inline comment',text,fixed=TRUE),grepl('# Final comment',text,fixed=TRUE))
cat('Syntax/runtime/Service diagnostics, multiline errors, caught errors, source validation, Echo/printing and shared graphics device PASSED\n')
