% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/RandomSearch.R
\docType{data}
\name{RandomSearchCV}
\alias{RandomSearchCV}
\title{Random Search CV}
\format{\code{\link{R6Class}} object.}
\usage{
RandomSearchCV
}
\description{
Given a set of hyper parameters, random search trainer provides a faster way of hyper parameter tuning.
Here, the number of models to be trained can be defined by the user.
}
\section{Usage}{

For usage details see \bold{Methods, Arguments and Examples} sections.
\preformatted{
rst = RandomSearchCV$new(trainer, parameters, n_folds, scoring, n_iter)
rst$fit(X_train, "target")
rst$best_iteration(metric)
}
}

\section{Methods}{

\describe{
  \item{\code{$new()}}{Initialises an instance of random search cv}
  \item{\code{$fit()}}{fit model to an input train data and trains the model.}
  \item{\code{$best_iteration()}}{returns best iteration based on a given metric. By default, uses the first scoring metric}
}
}

\section{Arguments}{

\describe{
 \item{trainer}{superml trainer object, must be either XGBTrainer, LMTrainer, RFTrainer, NBTrainer}
 \item{parameters}{list containing parameters}
 \item{n_folds}{number of folds to use to split the train data}
 \item{scoring}{scoring metric used to evaluate the best model, multiple values can be provided.
               currently supports: auc, accuracy, mse, rmse, logloss, mae, f1, precision, recall}
 \item{n_iter}{number of models to be trained}
}
}

\examples{
rf <- RFTrainer$new()
rst <-RandomSearchCV$new(trainer = rf,
                            parameters = list(n_estimators = c(100,500),
                            max_depth = c(5,2,10,14)),
                            n_folds = 3,
                            scoring = c('accuracy','auc'),
                            n_iter = 4)
data("iris")
rst$fit(iris, "Species")
rst$best_iteration()
}
\keyword{datasets}
