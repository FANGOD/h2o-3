#'
#' Find synonyms using a word2vec model.
#'
#' @param word2vec A word2vec model.
#' @param word A single word to find synonyms for.
#' @param count The top `count` synonyms will be returned.
#' @examples 
#' \dontrun{
#' library(h2o)
#' h2o.init()
#' 
#' job_titles <- h2o.importFile(
#'     "https://s3.amazonaws.com/h2o-public-test-data/smalldata/craigslistJobTitles.csv", 
#'     col.names = c("category", "jobtitle"), col.types = c("String", "String"), header = TRUE
#' )
#' words <- h2o.tokenize(job_titles, " ")
#' vec <- h2o.word2vec(training_frame = words)
#' h2o.findSynonyms(vec, "teacher", count = 20)
#' }
#' @export
h2o.findSynonyms <- function(word2vec, word, count = 20) {
    if (!is(word2vec, "H2OModel")) stop("`word2vec` must be a word2vec model")
    if (missing(word)) stop("`word` must be specified")
    if (!is.character(word)) stop("`word` must be character")
    if (!is.numeric(count)) stop("`count` must be numeric")

    res <- .h2o.__remoteSend(method="GET", "Word2VecSynonyms", model = word2vec@model_id,
                             word = word, count = count)
    fr <- data.frame(synonym = res$synonyms, score = res$scores)
    if (length(fr) > 0) {
        fr[with(fr, order(score, decreasing = TRUE)),]
    }
    fr
}

#'
#' Transform words (or sequences of words) to vectors using a word2vec model.
#'
#' @param word2vec A word2vec model.
#' @param words An H2OFrame made of a single column containing source words.
#' @param aggregate_method Specifies how to aggregate sequences of words. If method is `NONE`
#'    then no aggregation is performed and each input word is mapped to a single word-vector.
#'    If method is 'AVERAGE' then input is treated as sequences of words delimited by NA.
#'    Each word of a sequences is internally mapped to a vector and vectors belonging to
#'    the same sentence are averaged and returned in the result.
#' @examples
#' \dontrun{
#' h2o.init()
#'
#' # Build a dummy word2vec model
#' data <- as.character(as.h2o(c("a", "b", "a")))
#' w2v_model <- h2o.word2vec(data, sent_sample_rate = 0, min_word_freq = 0, epochs = 1, vec_size = 2)
#'
#' # Transform words to vectors without aggregation
#' sentences <- as.character(as.h2o(c("b", "c", "a", NA, "b")))
#' h2o.transform(w2v_model, sentences) # -> 5 rows total, 2 rows NA ("c" is not in the vocabulary)
#'
#' # Transform words to vectors and return average vector for each sentence
#' h2o.transform(w2v_model, sentences, aggregate_method = "AVERAGE") # -> 2 rows
#' }
#' @export
h2o.transform_word2vec <- function(word2vec, words, aggregate_method = c("NONE", "AVERAGE")) {
    if (!is(word2vec, "H2OModel")) stop("`word2vec` must be a word2vec model")
    if (missing(words)) stop("`words` must be specified")
    if (!is.H2OFrame(words)) stop("`words` must be an H2OFrame")
    if (ncol(words) != 1) stop("`words` frame must contain a single string column")

    if (length(aggregate_method) > 1)
        aggregate_method <- aggregate_method[1]

    res <- .h2o.__remoteSend(method="GET", "Word2VecTransform", model = word2vec@model_id,
                             words_frame = h2o.getId(words), aggregate_method = aggregate_method)
    key <- res$vectors_frame$name
    h2o.getFrame(key)
}

#' Convert a word2vec model into an H2OFrame
#'
#' Converts a given word2vec model into an H2OFrame. The frame represents learned word embeddings
#'
#' @param word2vec A word2vec model.
#' @examples
#' \dontrun{
#' h2o.init()
#'
#' # Build a dummy word2vec model
#' data <- as.character(as.h2o(c("a", "b", "a")))
#' w2v_model <- h2o.word2vec(data, sent_sample_rate = 0, min_word_freq = 0, epochs = 1, vec_size = 2)
#'
#' # Transform words to vectors and return average vector for each sentence
#' h2o.toFrame(w2v_model) # -> Frame made of 2 rows and 2 columns
#' }
#' @export
h2o.toFrame <- function(word2vec) {
    if (!is(word2vec, "H2OModel")) stop("`word2vec` must be a word2vec model")

    .newExpr("word2vec.to.frame", word2vec@model_id)
}
