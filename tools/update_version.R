# Keep the UI badge synchronized with both module version declarations.
mzRjStampVersion <- function(root=getwd()) {
    description <- read.dcf(file.path(root,'DESCRIPTION'))
    version <- unname(description[1,'Version'])
    lines <- readLines(file.path(root,'jamovi','0000.yaml'),warn=FALSE,encoding='UTF-8')
    declared <- sub('^version:[[:space:]]*','',grep('^version:',lines,value=TRUE))
    if(length(declared)!=1L || !identical(version,declared))
        stop('DESCRIPTION and jamovi/0000.yaml must declare the same module version.')
    if(!grepl('^[0-9]+([.-][0-9A-Za-z]+)*$',version))stop('Invalid module version.')
    writeLines(c('// Generated from DESCRIPTION; do not edit manually.',
        sprintf('module.exports = "%s";',version)),file.path(root,'jamovi','js','mzRj_version.js'),useBytes=TRUE)
    invisible(version)
}
if(sys.nframe()==0L) {
    args<-commandArgs(TRUE)
    mzRjStampVersion(if(length(args))args[1] else getwd())
}
