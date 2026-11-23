# Native Image objects must use the host options, including persisted resize scales.
.mzRj_imageFromProto <- function(self, item, clearWith='*', previousOptions=NULL) {
    image <- item$image
    oldScale <- function(axis) {
        key <- paste('results', item$name, paste0(axis, 'Scale'), sep='/')
        index <- if(is.null(previousOptions)) NA_integer_ else match(key,previousOptions$names)
        value <- if(is.na(index)) 1 else previousOptions$options[[index]]$d
        if(length(value)!=1L || !is.finite(value) || value<=0) 1 else value
    }
    widthM <- image$widthM; heightM <- image$heightM
    if(widthM==0 && image$widthB==0) widthM <- image$width/oldScale('width')
    if(heightM==0 && image$heightB==0) heightM <- image$height/oldScale('height')
    result <- jmvcore::Image$new(self$options,name=item$name,title=item$title,
        renderFun='.render',width=widthM,height=heightM,clearWith=clearWith)
    result$setSize2(widthM=widthM,heightM=heightM,widthB=image$widthB,heightB=image$heightB)
    result
}

# System R returns Images with its own Options object; rebind only Images.
.mzRj_bindImages <- function(self, group=self$results) {
    for(name in group$itemNames) {
        item <- group$get(name)
        if(inherits(item,'Image')) {
            result <- .mzRj_imageFromProto(self,item$asProtoBuf(status=3L))
            result$setState(item$state)
            group$add(result)
        } else if(inherits(item,'Group')) .mzRj_bindImages(self,item)
    }
}

# Invalidate just the resized raster; keep text, tables and Output untouched.
.mzRj_resizeImages <- function(group, pb, changes) {
    for(item in pb$elements) {
        result <- group$get(item$name)
        if(is.null(result)) next()
        if(item$has('image')) result$fromProtoBuf(item,changes,character())
        else if(item$has('group')) .mzRj_resizeImages(result,item$group,changes)
    }
}
