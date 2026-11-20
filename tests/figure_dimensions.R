# Run with an installed Rj and the current source root as the first argument.
args<-commandArgs(TRUE);root<-normalizePath(args[1],winslash='/')
library(Rj)
e<-new.env(parent=asNamespace('Rj'));sys.source(file.path(root,'R/eval.R'),envir=e)
code<-paste(
 'plot(1:5, main="Global dimensions")',
 'mzrjShowImage(function()plot(1:5), width=610, height=340, name="custom_image")',
 'mzrjShowImage(function()plot(1:5), width=560, name="ratio_image")',
 'mzrjShowSvg(function()plot(1:5), width=640, height=360, name="custom_svg")',sep='\n')
z<-e$eval(code,data.frame(),FALSE,root=jmvcore::Group$new(jmvcore::Options$new(),name=''),figWidth=700,figHeight=450)
items<-lapply(z$itemNames,function(n)z$get(n))
stopifnot(sum(vapply(items,inherits,logical(1),'Image'))==3L,
          sum(vapply(items,inherits,logical(1),'Svg'))==1L)
stopifnot(z$get('custom_image')$size$width==610,z$get('custom_image')$size$height==340,
          z$get('ratio_image')$size$width==560,z$get('ratio_image')$size$height==360,
          grepl('width="640"',z$get('custom_svg')$content,fixed=TRUE),
          grepl('height="360"',z$get('custom_svg')$content,fixed=TRUE),
          grepl('jmv-results-svg-selection',z$get('custom_svg')$content,fixed=TRUE))
stopifnot(inherits(try(e$eval('mzrjShowImage(function()plot(1),width=-1)',data.frame(),FALSE),silent=TRUE),'try-error'))
cat('Per-figure Image/Svg dimensions, global fallback, ratio, no duplicates and validation PASSED\n')
