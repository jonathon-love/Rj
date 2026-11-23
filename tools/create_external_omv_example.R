# Create the synthetic data-only OMV used by examples/02_external_omv.R.
# Run from the repository root, or pass that root as the first argument.
args <- commandArgs(trailingOnly=TRUE)
root <- normalizePath(if(length(args)) args[1] else ".", winslash="/")
stopifnot(file.exists(file.path(root,"examples","02_external_omv.R")))

baseline <- c(48,55,61,52,67,59,46,63,57,65,51,60,
              49,56,62,53,66,58,47,64,NA,68,54,60)
change <- c(1,-1,2,0,1,NA,-2,2,0,1,-1,2,
            7,5,8,6,9,7,5,8,6,9,7,8)
example <- data.frame(
    participant_id=sprintf("P%02d",seq_along(baseline)),
    group=factor(rep(c("Control","Training"),each=12),levels=c("Control","Training")),
    baseline_score=baseline,
    followup_score=baseline+change,
    sessions_attended=c(0,0,1,0,1,0,0,1,0,0,1,0,6,5,6,4,6,5,4,6,5,6,5,6),
    stringsAsFactors=FALSE)
attr(example$baseline_score,"jmv-desc") <- "Synthetic baseline score; not real participant data."
attr(example$followup_score,"jmv-desc") <- "Synthetic follow-up score; two missing values for demonstration."
attr(example$sessions_attended,"jmv-desc") <- "Synthetic attendance count."
folder <- file.path(root,"examples","omv")
dir.create(folder,recursive=TRUE,showWarnings=FALSE)
path <- file.path(folder,"02_external_omv.omv")
jmvReadWrite::write_omv(example,path)
readback <- jmvReadWrite::read_omv(path,sveAtt=TRUE)
stopifnot(nrow(readback)==24L,identical(names(readback),names(example)),
    identical(as.character(readback$participant_id),example$participant_id),
    identical(as.character(readback$group),as.character(example$group)))
for(name in c("baseline_score","followup_score","sessions_attended"))
    stopifnot(isTRUE(all.equal(as.numeric(readback[[name]]),as.numeric(example[[name]]))))
cat("Created and verified:",path,"\n")
