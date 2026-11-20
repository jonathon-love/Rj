# Operazioni sui file editor separate dall'esecuzione del codice utente.
.mzRj_saveEditor <- function(self) {
    action <- jmvcore::OptionAction$new('saveEditorScript', value=TRUE, action='export')
    self$options$.addOption(action)
    previous <- self$results$get('saveEditorScript')
    if (!is.null(previous)) previous$clear()
    action$perform(function(request) {
        state <- self$options$editorState
        filename <- state$filename
        if (is.null(filename) || !nzchar(filename)) filename <- 'script.R'
        filename <- basename(gsub('\\', '/', filename, fixed=TRUE))
        if (!grepl('\\.[Rr]$', filename)) filename <- paste0(filename, '.R')
        code <- if(isTRUE(state$hasDraft)) state$draft else self$options$code
        writeBin(charToRaw(enc2utf8(code)), request$params$fullPath)
        list(filename=filename)
    })
}

.mzRj_editorCode <- function(self) self$options$code

.mzRj_editorSources <- function(self) {
    state<-self$options$editorState
    list(editorName=if(is.null(state$filename)||!nzchar(state$filename)).('R editor') else state$filename,
         serviceName=if(is.null(state$serviceName)||!nzchar(state$serviceName)).('Service script') else state$serviceName,
         serviceCode=if(is.null(state$serviceCode))'' else state$serviceCode)
}

# Ricostruzione dei tipi usati da Rj e dai risultati strutturati ospitati.
.mzRj_restoreResults <- function(self, groupPB, clearWith, previousOptions=NULL) {
    restore <- function(group, pb) {
        for (item in pb$elements) {
            if (!is.null(group$get(item$name))) next()
            args <- list(options=self$options, name=item$name, title=item$title, clearWith=clearWith)
            result <- NULL
            if(item$has('preformatted')) result <- do.call(jmvcore::Preformatted$new,args)
            else if(item$has('image')) result <- .mzRj_imageFromProto(self,item,clearWith,previousOptions)
            else if(item$has('html')) result <- do.call(jmvcore::Html$new,args)
            else if(item$has('svg')) result <- do.call(jmvcore::Svg$new,args)
            else if(item$has('text')) result <- do.call(jmvcore::Text$new,args)
            else if(item$has('table')) {
                result <- do.call(jmvcore::Table$new,c(args,list(swapRowsColumns=item$table$swapRowsColumns)))
                for(column in item$table$columns) result$addColumn(name=column$name,title=column$title,
                    type=column$type,format=column$format,
                    superTitle=if(nzchar(column$superTitle))column$superTitle else NULL,
                    combineBelow=column$combineBelow)
                for(row in item$table$rowNames) result$addRow(rowKey=jmvcore:::fromJSON(row))
            } else if(item$has('group')) {
                result <- do.call(jmvcore::Group$new,args)
                restore(result,item$group)
            }
            if(!is.null(result)) group$add(result)
        }
    }
    restore(self$results,groupPB)
}
