# Cross-language reference from the accepted Pj helper, not a second R formula copy.
args<-commandArgs(TRUE);root<-normalizePath(args[1],winslash='/')
source(file.path(root,'tests/helper_paths.R'));mzRjTestPaths(root)
library(Rj)
prepare<-getFromNamespace('.mzRj_barberJohnsonPrepare','Rj')
fixture<-jsonlite::fromJSON(file.path(root,'tests/fixtures/barber_johnson.json'),simplifyVector=FALSE)
# Numeric reference vectors are R vectors; points/scenarios retain JSON list shape.
for(i in seq_along(fixture$cases)) {
    options<-c(fixture$common,fixture$cases[[i]])
    options$scenarios<-lapply(options$scenarios,function(s){s$bor<-unlist(s$bor);s$toi<-unlist(s$toi);s})
    actual<-do.call(prepare,c(list(dataset=fixture$data),options))
    expected<-fixture$expected;expected$view<-actual$view
    difference<-all.equal(actual,expected,tolerance=1e-12,check.attributes=FALSE)
    if(!isTRUE(difference))stop('Reference case ',i,': ',paste(difference,collapse='; '))
}
reject<-function(data=fixture$data,...)stopifnot(inherits(tryCatch(prepare(data,...),error=identity),'error'))
bad<-fixture$data;bad$discharges[[1]]<-1.5;reject(bad)
bad<-fixture$data;bad$occupied_bed_days[[1]]<-1e8;reject(bad)
bad<-fixture$data;bad$period[[2]]<-bad$period[[1]];reject(bad)
bad<-fixture$data;bad$bor[[1]]<-80;reject(bad,input_mode='alos_bor')
reject(view='trajectory');reject(size_by_beds=1);reject(period_days=0)
reject(scenarios=list(list(label='bad',bor=c(.8,1))))
reject(scenarios=list(list(label='x',bor=.8),list(label='x',bor=.9)))
bad<-fixture$data;bad$occupied_bed_days[[1]]<-NA_real_
actual<-prepare(bad);stopifnot(length(actual$points)==11L,identical(actual$excludedRows,list(1L)))
original<-serialize(fixture$data,NULL);set.seed(17);random<-.Random.seed
invisible(prepare(fixture$data));stopifnot(identical(serialize(fixture$data,NULL),original),identical(.Random.seed,random))
cat('Thirteen Pj reference cases, invalid inputs, exclusion, no mutation/RNG changes PASSED\n')
