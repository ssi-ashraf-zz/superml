#' Count Vectorizer
#' @description Creates CountVectorizer Model.
#' Given a list of text, it generates a bag of words model and returns a data frame consisting of BOW features.
#' @format \code{\link{R6Class}} object.
#' @section Usage:
#' For usage details see \bold{Methods, Arguments and Examples} sections.
#' \preformatted{
#' bst = CountVectorizer$new(min_df=1, max_df=1, max_features=1)
#' bst$fit(sentences)
#' bst$fit_transform(sentences)
#' bst$transform(sentences)
#' }
#'
#' @section Methods:
#' \describe{
#'     \item{\code{$new()}}{Initialise the instance of the vectorizer}
#'     \item{\code{$fit()}}{creates a memory of bag of words}
#'     \item{\code{$transform()}}{based on encodings learned in \code{fit} method, return a bag of words matrix }
#'     \item{\code{$fit_transform()}}{simultaneouly fits and transform words and returns bag of words of matrix}
#' }
#' @section Arguments:
#' \describe{
#'     \item{sentences}{input vector or list consisting of text}
#'     \item{min_df}{consider tokens which occur in atleast this % documents, value lies between 0 and 1}
#'     \item{max_df}{consider tokens which occur in maximum this % documents, value lies between 0 and 1}
#'     \item{max_features}{use top features sorted by count to be used in bag of words matrix}
#' }
#' @export
#' @examples
#' df <- data.frame(sents = c('i am alone in dark.','mother_mary a lot',
#'                            'alone in the dark?',
#'                            'many mothers in the lot....'))
#'
#' # fits and transforms on the entire data in one go
#' bw <- CountVectorizer$new(min_df = 0.3)
#' tf_features <- bw$fit_transform(df$sents)
#'
#' # fit on entire data and do transformation in train and test
#' bw <- CountVectorizer$new()
#' bw$fit(df$sents)
#' tf_features <- bw$transform(df$sents)

CountVectorizer <- R6Class("CountVectorizer", public = list(

    sentences = NA,
    max_df = 1, # should be between 0 and 1
    min_df = 1, # should be between 0 and 1
    max_features = 1, # should be integer value 1 means get all features
    split = " ",# default is space
    regex = "[^a-zA-Z0-9 ]",
    model = NULL,
    remove_stopwords = TRUE,
    str=NULL,


    initialize = function(min_df, max_df, max_features,regex, remove_stopwords, split){
        if(!(missing(max_df))) self$max_df <- max_df
        if(!(missing(min_df))) self$min_df <- min_df
        if(!(missing(max_features))) self$max_features <- max_features
        if(!(missing(regex))) self$regex <- regex
        if(!(missing(remove_stopwords))) self$remove_stopwords <- remove_stopwords
        if(!(missing(split))) self$split <- split
        private$check_args(self$max_df, what='max_df')
        private$check_args(self$min_df, what='min_df')

    },

    fit = function(sentences){


        sentences <- private$preprocess(sentences,
                                        regex=self$regex,
                                        remove_stopwords = self$remove_stopwords)
        ## pass cleaned sentences here
        ## this function returns a vector of tokens to be
        ## used as subset in next steps
        use_tokens <- private$get_tokens(sentences,
                                        min_df = self$min_df,
                                        max_df = self$max_df,
                                        max_features = self$max_features)

        self$model <- private$get_bow_df(sentences,
                                         split_rule = self$split,
                                         use_tokens=use_tokens)


    },

    fit_transform = function(sentences){

    },

    transform = function(sentences){


    }),

    private =  list(

        preprocess = function(sentences, regex="[^0-9a-zA-Z ]", remove_stopwords){


            # this function returns cleaned sentences
            s <- gsub(regex, "", sentences)

            if(isTRUE(remove_stopwords)){

                path = system.file("stopwords","english.txt", package = "superml")
                stopwords <- read.csv(path, header = F, stringsAsFactors = F)[,1]

                # remove stopwords from sentences
                sw_pattern = paste0("\\b(?:", paste(stopwords, collapse = "|"), ")\\b ?")
                s <- gsub(pattern = sw_pattern, replacement = '', s, perl = T)

                return(s)

            }
            return (s)
        },


        get_tokens = function(sentences, min_df=1, max_df=1, max_features=1, split=NULL){


            # sentences should be preprocessed sentences

            # here and use only those tokens which are necessarily required
            # instead of creating a matrix for all the words
            tokens_counter <- sort(table(tm::Boost_tokenizer(sentences)), decreasing = TRUE)

            # max features should not be greater than max. value
            if(max_features > length(tokens_counter))
                stop('max_features cannot be greater than maximum possible
                     features. Please pass a smaller value.')

            # max_feature will override other two parameters (min_df, max_df)
            use_tokens <- NULL

            # this is default value, use all tokens
            if (max_features == 1){
                 return(names(tokens_counter))
            }

            if(max_features > 1){
                return (names(tokens_counter)[1:max_features])
            }

            # min_df = keep tokens that occur in atleast this % documents (lower_limit)
            # max_df = keep tokens that occur in at max this % documents (upper_limit)

            if(min_df > max_df) {
                stop("min_df cannot be greater than max_df.
                     Please use another value.")
            } else if(min_df == 1 & max_df == 1) {
                return (names(tokens_counter))
            }

            # get upper and lower limit values
            lower_limit <- round(length(sentences) * min_df)
            upper_limit <- round(length(sentences) * max_df)

            return (list(lower=lower_limit, upper=upper_limit))

        },

        get_bow_df = function(sentences, split_rule=" ", use_tokens=NULL){

            # calculate count of tokens across all documents
            f <- rbindlist(
                lapply(
                    mapply(
                        cbind, seq(sentences),
                        strsplit(sentences, split=split_rule)), data.table), fill=TRUE)

            f <- Matrix::Matrix(Matrix::as.matrix(dcast.data.table(f,
                                  V1 ~ V2,
                                  fun.aggregate= length,
                                  value.var="V2")[,-1]), sparse = TRUE)

            if(is.character(use_tokens)){

                return(as.matrix(f[,use_tokens]))


            } else {

                # get count of columns
                mat <- Matrix::colSums(f)

                # check lower and upper limit
                use_tokens <- names(mat[mat > lower_limit &
                                            mat < upper_limit])

                return(as.matrix(f[, use_tokens]))

            }

        },

        check_args = function(x, max_value, what){
            if (what == 'max_features'){
                if(x < 0 )
                    stop(sprintf('The value for %s cannot be below zero', x))
                if(x > max_value){
                    stop(sprintf('The value for %s cannot be
                             more than max. possible features', x))
                }
            }

            if(what %in% c('min_df','max_df')){
                if(x < 0 | x >1)
                    stop(sprintf('The value for %s cannot be below zero', x))

            }

        }

    )

)





