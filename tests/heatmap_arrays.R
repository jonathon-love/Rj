# Named R vectors and matrix rows must become JSON arrays, never objects.
a<-commandArgs(TRUE);root<-a[1]
source(file.path(root,'tests/helper_paths.R'));mzRjTestPaths(root)
library(Rj);run<-getFromNamespace('eval','Rj')
z<-run('mzrjShowHeatmap(cor(iris[1:4]),name="matrix",zmin=-1,zmax=1,zmid=0);mzrjShowChart("bar",list(list(data=c(A=1,B=2))),labels=c(A="Alpha",B="Beta"),name="chart");mzrjShowPlotly(list(data=list(list(type="scatter",x=c(A=1,B=2),y=c(A=3,B=4)))),name="plotly")',data.frame(),FALSE)
stopifnot(grepl('"z":[[1,',z$get('matrix')$content,fixed=TRUE),!grepl('"z":[{',z$get('matrix')$content,fixed=TRUE),
 grepl('"labels":["Alpha","Beta"]',z$get('chart')$content,fixed=TRUE),
 grepl('"data":[1,2]',z$get('chart')$content,fixed=TRUE),
 grepl('"x":[1,2],"y":[3,4]',z$get('plotly')$content,fixed=TRUE))
cat('Named matrix rows, Chart arrays and Plotly coordinates PASSED\n')
