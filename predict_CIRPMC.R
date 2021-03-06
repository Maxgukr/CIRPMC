#!/usr/bin/env Rscript
# install.packages('caret', repos = "http://cran.us.r-project.org")
library(caret)

run <- function(infile, outfile){
  load('./data.RData')
  
  tmp <- read.csv('./features.csv')
  tmp$X <- NULL
  fs <- as.vector(t(tmp)[, 1])
  # infile <- 'server/test_X.csv'
  X <- read.csv(infile)
  colnames(X) <- fs
  for (f in fs){
    X[[f]] <- as.numeric(X[[f]])
  }
  pred_df <- pred_models(model_list, X[, fs])
  write.csv(pred_df, outfile, row.names = F, quote=F)
}

pred_models <- function(model_list, X){ 
  LR_y_pred <- pred_func(model_list$LR, X)
  SVM_y_pred <- pred_func(model_list$SVM, X)
  RF_y_pred <- pred_func(model_list$RF, X)
  GBDT_y_pred <- pred_func(model_list$GBDT, X)
  NN_y_pred <- pred_func(model_list$NN, X)
  df <- data.frame("LR"=LR_y_pred, "SVM"=SVM_y_pred, "RF"=RF_y_pred, "GBDT"=GBDT_y_pred, 'NN'=NN_y_pred)
  rownames(df) <- rownames(X)
  colnames(df) <- c('LR', 'SVM', 'RF', 'GBDT', 'NN')
  df$Probability <- df$LR*.09 + df$GBDT*0.9 +  df$NN*.01
  df$Cluster <- as.factor(as.numeric(df$Probability > 0.5))
  df$`Risk group`[df$Cluster == '0'] <- 'Non critical'
  df$`Risk group`[df$Cluster == '1'] <- 'Critical'
  return(df)
}

pred_func <- function(model, X){
  pred_y <- predict(model, newdata = X, type='prob')[[2]]
  return (pred_y)
}


library("optparse")
# run CIRPMC (critical illness risk prediction model for COVID-19)
option_list = list(
  make_option(c("-i", "--infile"), type="character", default=NULL, 
              help="Path of X input file", metavar="character"),
  make_option(c("-o", "--outfile"), type="character", default=NULL, 
              help="Path of Y output file", metavar="character")
); 

opt_parser = OptionParser(option_list=option_list);
opt = parse_args(opt_parser);


if (is.null(opt$infile) || is.null(opt$outfile)){
  print_help(opt_parser)
  stop("input and output file path must be supplied.", call.=FALSE)
}

run(opt$infile, opt$outfile)
