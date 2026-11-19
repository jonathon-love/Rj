# Optional overrides: MZRJ_TEST_LIBS and MZRJ_SYSTEM_RSCRIPT.
# Normal use: run with jamovi R and pass the compiled source directory.
mzRjTestPaths <- function(root) {
 candidates<-list.dirs(file.path(root,'build'),recursive=FALSE,full.names=TRUE)
 candidates<-candidates[file.exists(file.path(candidates,'Rj','DESCRIPTION'))]
 runtime<-c(file.path(R.home(),'../../Resources/modules/base/R'),
            file.path(R.home(),'../jamovi/modules/base/R'),
            file.path(R.home(),'../../../../../Resources/modules/base/R'))
 extra<-strsplit(Sys.getenv('MZRJ_TEST_LIBS'),.Platform$path.sep,fixed=TRUE)[[1]]
 .libPaths(unique(c(candidates,extra,runtime[dir.exists(runtime)],.libPaths())))
}
mzRjSystemRscript <- function() {
 executable<-Sys.getenv('MZRJ_SYSTEM_RSCRIPT',unset=Sys.which('Rscript'))
 if(!nzchar(executable)||!file.exists(executable))
   stop('Set MZRJ_SYSTEM_RSCRIPT to the System Rscript executable.')
 executable
}
