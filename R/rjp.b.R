
RjpClass <- R6::R6Class(
    "RjpClass",
    inherit = RjClass,
    active=list(
        saveColumns=function() TRUE
    ),
    public=list(
        initialize=function(...) {
            super$initialize(...)
            private$.name <- 'Rjp'
        }
    )
)
