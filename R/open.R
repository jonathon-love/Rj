
open <- function(data = NULL, title = "") {
    jmvReadWrite:::jmvOpn(dtaFrm = data, dtaTtl = title, rtnOut = FALSE)
}

newWin  <- open
newSess <- open
