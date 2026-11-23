# External data are session-scoped and never replace the current jamovi dataset.
.mzRj_setOption <- function(self,name,value) {
    pb<-self$options$asProtoBuf()
    if(is.null(pb)){pb<-RProtoBuf::new(RProtoBuf::P('jamovi.coms.AnalysisOptions'));pb$hasNames<-TRUE}
    i<-match(name,pb$names)
    if(is.na(i)){pb$names<-c(pb$names,name);pb$add('options',RProtoBuf::new(RProtoBuf::P('jamovi.coms.AnalysisOption')));i<-length(pb$names)}
    if(is.null(value))pb$options[[i]]$o<-2L else if(is.logical(value)){pb$options[[i]]$o<-if(value)1L else 0L} else {
        group<-RProtoBuf::new(RProtoBuf::P('jamovi.coms.AnalysisOptions'));group$hasNames<-TRUE;group$names<-'json'
        child<-RProtoBuf::new(RProtoBuf::P('jamovi.coms.AnalysisOption'));child$s<-value;group$add('options',child);pb$options[[i]]$c<-group
    }
    self$options$fromProtoBuf(pb)
}
.mzRj_omvState <- function(self) {item<-self$results$get('omvExport');if(is.null(item))NULL else item$state}
.mzRj_omvRestore <- function(self,state) {
    item<-self$results$get('omvExport')
    if(is.null(item)){item<-jmvcore::Html$new(self$options,'omvExport',visible=FALSE,clearWith=character());self$results$add(item)}
    item$setState(state);item$setContent('')
}
.mzRj_omvPath <- function(self,state=.mzRj_omvState(self)) {
    id<-state$cache_id
    if(is.null(id))return(NULL)
    if(!is.character(id)||length(id)!=1L||!grepl('^mzrj-dataext-[a-zA-Z0-9]+$',id))stop(.('Invalid external dataset cache.'),call.=FALSE)
    file.path(tryCatch(self$.getSessionTemp(),error=function(e)tempdir()),id)
}
.mzRj_dataext <- function(self) {
    path<-.mzRj_omvPath(self)
    if(is.null(path))return(data.frame())
    if(!file.exists(paste0(path,'.rds')))stop(.('External data are no longer available. Read the OMV again.'),call.=FALSE)
    readRDS(paste0(path,'.rds'))
}
.mzRj_stageDataext <- function(self,data,source='') {
    if(!is.data.frame(data))stop(.('dataext must be an R data.frame.'),call.=FALSE)
    if(ncol(data)==0L){.mzRj_omvRestore(self,NULL);return(invisible(NULL))}
    if(anyNA(names(data))||any(!nzchar(names(data)))||anyDuplicated(names(data)))stop(.('dataext needs unique, non-empty column names.'),call.=FALSE)
    if(as.double(object.size(data))>32*1024^2)stop(.('External dataset exceeds the 32 MiB session limit.'),call.=FALSE)
    root<-tryCatch(self$.getSessionTemp(),error=function(e)tempdir())
    path<-tempfile('mzrj-dataext-',tmpdir=root);valid<-FALSE
    on.exit(if(!valid)unlink(c(paste0(path,'.rds'),paste0(path,'.omv'))))
    saveRDS(data,paste0(path,'.rds'))
    jmvReadWrite::write_omv(data,paste0(path,'.omv'))
    .mzRj_omvRestore(self,list(cache_id=basename(path),source_name=source,rows=nrow(data),columns=ncol(data)))
    valid<-TRUE;invisible(NULL)
}
.mzRj_omvInfo <- function(self) {
    state<-.mzRj_omvState(self);path<-.mzRj_omvPath(self)
    ready<-!is.null(path)&&file.exists(paste0(path,'.omv'))
    info<-list(ready=ready,name=if(ready){if(nzchar(state$source_name))state$source_name else .('Created in R')}else if(!is.null(path)).('Unavailable - read again') else .('Empty'),rows=state$rows,columns=state$columns)
    .mzRj_setOption(self,'dataextInfo',as.character(jsonlite::toJSON(info,auto_unbox=TRUE,null='null')))
}
.mzRj_omvPreview <- function(self) {
    item<-self$results$get('dataextPreview')
    if(is.null(item)){item<-jmvcore::Html$new(self$options,'dataextPreview',title=.('External dataset preview'),visible=FALSE,clearWith=character());self$results$add(item)}
    path<-.mzRj_omvPath(self)
    visible<-isTRUE(self$options$previewDataext)&&!is.null(path)&&file.exists(paste0(path,'.rds'))
    item$setVisible(visible)
    if(!visible){item$setContent('');return(invisible(NULL))}
    data<-readRDS(paste0(path,'.rds'));data<-head(data[,seq_len(min(12L,ncol(data))),drop=FALSE],20L)
    esc<-function(x){x<-substr(as.character(x),1,160);x[is.na(x)]<-'NA';x<-gsub('&','&amp;',x,fixed=TRUE);x<-gsub('<','&lt;',x,fixed=TRUE);gsub('>','&gt;',x,fixed=TRUE)}
    header<-paste0('<th>',esc(names(data)),'</th>',collapse='')
    rows<-vapply(seq_len(nrow(data)),function(i)paste0('<tr>',paste0('<td>',esc(vapply(data,function(x)as.character(x[i]),character(1))),'</td>',collapse=''),'</tr>'),character(1))
    item$setContent(paste0('<section style="width:760px;max-width:100%;contain:inline-size"><p>',.('External dataset: first 20 rows and 12 columns at most. Save includes all data.'),'</p><div style="max-height:340px;overflow:auto"><table style="border-collapse:separate;border-spacing:10px 6px"><thead><tr>',header,'</tr></thead><tbody>',paste(rows,collapse=''),'</tbody></table></div></section>'))
}
.mzRj_saveOmv <- function(self) {
    action<-jmvcore::OptionAction$new('saveOmvFile',value=TRUE,action='export');self$options$.addOption(action)
    previous<-self$results$get('saveOmvFile');if(!is.null(previous))previous$clear()
    action$perform(function(request){
        path<-.mzRj_omvPath(self)
        if(is.null(path)||!file.exists(paste0(path,'.omv')))stop(.('Read an OMV or create dataext and Run before saving.'),call.=FALSE)
        if(!file.copy(paste0(path,'.omv'),request$params$fullPath,overwrite=TRUE))stop(.('Unable to prepare OMV export.'),call.=FALSE)
        list(filename='dataext.omv')
    })
}
.mzRj_omvAction <- function(self) {
    on.exit(.mzRj_omvInfo(self))
    if(isTRUE(self$options$saveOmvFile)){.mzRj_saveOmv(self);return(TRUE)}
    file<-self$options$omvFile
    if(!is.null(file)) {
        on.exit(.mzRj_setOption(self,'omvFile',NULL),add=TRUE)
        size<-file.info(file$path)$size
        if(length(size)!=1L||is.na(size)||size>32*1024^2)stop(.('Selected OMV exceeds the 32 MiB input limit.'),call.=FALSE)
        data<-jmvReadWrite::read_omv(file$path,sveAtt=TRUE)
        .mzRj_stageDataext(self,data,file$filename);.mzRj_omvPreview(self);return(TRUE)
    }
    if(isTRUE(self$options$previewDataextRequest)) {
        on.exit(.mzRj_setOption(self,'previewDataextRequest',FALSE),add=TRUE)
        .mzRj_omvPreview(self);return(TRUE)
    }
    FALSE
}

.mzRj_remoteMessages <- function(self) list(
    "To use the system R from jamovi, a newer version of jmvReadWrite (> 0.4.9) is required."=.("To use the system R from jamovi, a newer version of jmvReadWrite (> 0.4.9) is required."),
    "openNew() requires that jmvReadWrite is installed in your system R installation."=.("openNew() requires that jmvReadWrite is installed in your system R installation."),
    "openNew() is not available under 'system R' on Linux systems."=.("openNew() is not available under 'system R' on Linux systems."),
    "Unknown error"=.("Unknown error"),
    "System R is missing required packages:"=.("System R is missing required packages:"),
    "R editor"=.("R editor"), "Service script"=.("Service script"),
    "line"=.("line"), "Error"=.("Error"),
    "The plot argument must be a function with no arguments."=.("The plot argument must be a function with no arguments."),
    "Figure dimensions must be whole numbers from 1 to 10000 pixels."=.("Figure dimensions must be whole numbers from 1 to 10000 pixels."),
    "Use a unique result name containing letters, digits or underscores."=.("Use a unique result name containing letters, digits or underscores."),
    "The figure title must be a single string."=.("The figure title must be a single string."),
    "Syntax error"=.("Syntax error"), "Called from"=.("Called from")
)
