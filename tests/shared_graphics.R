# Real evaluator fixtures and invariants for Embedded/System R adapters.
a<-commandArgs(TRUE);root<-normalizePath(a[1],winslash='/');out<-normalizePath(a[2],winslash='/',mustWork=FALSE)
dir.create(out,recursive=TRUE,showWarnings=FALSE)
source(file.path(root,'tests/helper_paths.R'));mzRjTestPaths(root)
library(Rj)
run<-getFromNamespace('eval','Rj')
manifest<-list()
for(mode in c('html','svg','image')) {
 code<-paste0('RESULT_TYPE<-"',mode,'"\n',paste(readLines(file.path(root,'examples/07_shared_graphics.R')),collapse='\n'))
 code<-sub('RESULT_TYPE <- "html"',paste0('RESULT_TYPE <- "',mode,'"'),code,fixed=TRUE)
 results<-run(code,data.frame(),FALSE)
 for(name in c('iris_d3','iris_plotly','iris_chart','profile_plotly')) {
  item<-results$get(name);stopifnot(!is.null(item))
  stopifnot(inherits(item,if(mode=='svg')'Svg' else 'Html'))
  if(mode!='html')stopifnot(!grepl('<details',item$content,fixed=TRUE))
  if(mode=='image')stopifnot(grepl('^[a-f0-9]{32}$',item$state$image_capture_token))
  stopifnot(!grepl('__[A-Z_]+__',item$content))
  filename<-paste0(name,'_',mode,'.html');writeLines(item$content,file.path(out,filename),useBytes=TRUE)
  manifest[[length(manifest)+1L]]<-list(file=filename,name=name,mode=mode)
 }
}
for(mode in c('html','svg','image')) {
 code<-paste(readLines(file.path(root,'examples/09_guided_graphics.R')),collapse='\n')
 code<-sub('RESULT_TYPE <- "html"',paste0('RESULT_TYPE <- "',mode,'"'),code,fixed=TRUE)
 results<-run(code,data.frame(),FALSE)
 for(name in c('length_histogram','guided_profiles','guided_counts','correlation_heatmap')) {
  item<-results$get(name);stopifnot(!is.null(item))
  filename<-paste0(name,'_',mode,'.html');writeLines(item$content,file.path(out,filename),useBytes=TRUE)
  manifest[[length(manifest)+1L]]<-list(file=filename,name=name,mode=mode)
 }
}
# No RNG consumption: graphics preparation cannot change subsequent analysis.
set.seed(42);expected<-runif(4);set.seed(42)
run('mzrjShowBoxplot(iris,"Sepal.Length",group="Species");mzrjShowChart("bar",list(list(data=c(1,2))),labels=c("A","B"))',data.frame(),FALSE)
stopifnot(identical(runif(4),expected))
# Missing pairs are excluded, factors are categories, single-row arrays stay arrays.
z<-run('mzrjShowScatter(data,"x","y",group="g",name="one")',data.frame(x=c(1,NA),y=c(2,3),g=factor(c('A','B'))),FALSE)
stopifnot(grepl('"points":[{',z$get('one')$content,fixed=TRUE),grepl('"groups":["A"]',z$get('one')$content,fixed=TRUE))
# Explicit values do not change with the popup; omitted values use each own axis.
code<-paste(readLines(file.path(root,'examples/08_graphic_dimensions.R')),collapse='\n')
z<-run(code,data.frame(),FALSE,figWidth=720,figHeight=480)
stopifnot(grepl('"width":720',z$get('global_d3')$content,fixed=TRUE),grepl('"height":480',z$get('global_d3')$content,fixed=TRUE),
 grepl('"width":600',z$get('fixed_plotly')$content,fixed=TRUE),grepl('width:560px;height:320px',z$get('fixed_chart')$content,fixed=TRUE))
# Input is data, even when a label contains a closing script tag.
z<-run('mzrjShowBar(data,"group",name="safe")',data.frame(group='</script><script>window.bad=1</script>'),FALSE)
stopifnot(!grepl('</script><script>window.bad',z$get('safe')$content,fixed=TRUE))
for(code in c('mzrjShowScatter(iris,"Species","Sepal.Length")','mzrjShowChart("bar",list(list(data=c(1,2))),labels="A")','mzrjShowPlotly(list(data=list()),width=-1)','mzrjShowBar(data.frame(a=c("A","A"),b=1:2),"a","b",stat="identity")'))
 stopifnot(inherits(tryCatch(run(code,data.frame(),FALSE),error=identity),'error'))
writeLines(jsonlite::toJSON(manifest,auto_unbox=TRUE,pretty=TRUE),file.path(out,'fixtures.json'))
cat('Shared graphics evaluator, names, dimensions, native contracts, no RNG changes, JSON safety and validation PASSED\n')
