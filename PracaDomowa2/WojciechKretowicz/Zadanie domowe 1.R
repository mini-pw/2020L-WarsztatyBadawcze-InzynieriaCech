library(OpenML)
library(data.table)
library(mlr)

cross_val = function(data, cv, seed=77) {
  set.seed(seed)
  n = nrow(data)
  I = sample(n)
  a = floor(n/cv)
  
  result = list()
  for(i in 1:cv) {
    result[[i]] = I[((i-1)*a+1):(i*a)]
  }
  
  result
}

cross_val_score = function(data, cv, seed=77) {
  library(glmnet)
  cv = cross_val(data, cv, seed)
  result_auroc = c()
  result_auprc = c()
  for(I in cv) {
    model = glm(Class~., data=data[-I, ], family='binomial')
    probs = predict(model, newdata = data[I, ], type = "response")
    fg = probs[data[I,]$Class == 1]
    bg = probs[data[I,]$Class == 0]
    
    library(PRROC)
    # ROC Curve    
    roc <- roc.curve(scores.class0 = fg, scores.class1 = bg, curve = T)
    
    # PR Curve
    pr <- pr.curve(scores.class0 = fg, scores.class1 = bg, curve = T)
    result_auroc = c(result_auroc, roc$auc)
    result_auprc = c(result_auprc, pr$auc.integral)
  }
  print(mean(result_auroc))
  print(sd(result_auroc))
  
  print(mean(result_auprc))
  print(sd(result_auprc))
}

cross_val_score2 = function(data, model, cv, seed=77) {
  library(glmnet)
  cv = cross_val(data, cv, seed)
  result_auroc = c()
  result_auprc = c()
  for(I in cv) {
    task = makeClassifTask(data=data[-I, ], target='Class')
    task_test = makeClassifTask(data=data[I, ], target='Class')
    trained = train(model, task)
    probs = predict(trained, task_test, type = "response")$data$prob.1
    fg = probs[data[I,]$Class == 1]
    bg = probs[data[I,]$Class == 0]
    
    library(PRROC)
    # ROC Curve    
    roc <- roc.curve(scores.class0 = fg, scores.class1 = bg, curve = T)
    
    # PR Curve
    pr <- pr.curve(scores.class0 = fg, scores.class1 = bg, curve = T)
    result_auroc = c(result_auroc, roc$auc)
    result_auprc = c(result_auprc, pr$auc.integral)
  }
  #print(mean(result_auroc))
  #print(sd(result_auroc))
  
  #print(mean(result_auprc))
  #print(sd(result_auprc))
  
  list(mean(result_auprc), sd(result_auprc), mean(result_auroc), sd(result_auroc))
}

cross_val_score3 = function(data, cv, seed=77) {
  set.seed(seed) 
  library(glmnet)
  cv = cross_val(data, cv, seed)
  result_auroc = c()
  result_auprc = c()
  for(I in cv) {
    task = mlr::makeClassifTask(data=data[-I, ], target = 'Class')
    task_test = mlr::makeClassifTask(data=data[I, ], target = 'Class')
    model = mlr::makeLearner('classif.rpart', predict.type = 'prob')
    params = makeParamSet( 
      makeDiscreteParam("minsplit", values=seq(5,10,1)), makeDiscreteParam("minbucket", values=seq(round(5/3,0), round(10/3,0), 1)), 
      makeNumericParam("cp", lower = 0.01, upper = 0.05), makeDiscreteParam("maxcompete", values=6), makeDiscreteParam("usesurrogate", values=0), makeDiscreteParam("maxdepth", values=10) )
    ctrl = makeTuneControlGrid()
    rdesc = makeResampleDesc("CV", iters = 5L, stratify=TRUE)
    dt_tuneparam <- tuneParams(learner=model, 
                               resampling=rdesc, 
                               measures=list(tpr,auc, fnr, mmce, tnr, setAggregation(tpr, test.sd)), 
                               par.set=params, 
                               control=ctrl, 
                               task=task, 
                               show.info = TRUE)
    

    model = mlr::makeLearner('classif.rpart', predict.type = 'prob', par.vals = dt_tuneparam$x)
    model = train(model, task)
    probs = predict(model, task_test)$data$prob.1
    fg = probs[data_test$Class == 0]
    bg = probs[data_test$Class == 1]
    
    # ROC Curve    
    roc <- roc.curve(scores.class0 = fg, scores.class1 = bg, curve = T)
    
    # PR Curve
    pr <- pr.curve(scores.class0 = fg, scores.class1 = bg, curve = T)
    
    result_auroc = c(result_auroc, roc$auc)
    result_auprc = c(result_auprc, pr$auc.integral)
  }
  print(mean(result_auroc))
  print(sd(result_auroc))
  
  print(mean(result_auprc))
  print(sd(result_auprc))
}

preprocess = function(data) {
  which(colnames(data) == 'sick')
  which(colnames(data) == 'hypopituitary')
  which(colnames(data) == 'TSH_measured')
  which(colnames(data) == 'T3_measured')
  which(colnames(data) == 'TT4_measured')
  which(colnames(data) == 'T4U_measured')
  which(colnames(data) == 'FTI_measured')
  which(colnames(data) == 'TBG_measured')
  which(colnames(data) == 'TBG')
  data = data[, -c(6,15,17,19,21,23,25,27,28)]
  #data = data[, -c(28)]
  
  data = data[data$age < 100, ]
  data = data[data$TSH < 100, ]
  data = data[data$T3 < 30, ]
  data = data[data$TT4 < 400, ]
  data = data[data$FTI < 400, ]
  
  data = data[!apply(is.na(data), 1, all),]
  
  tsh = EnvStats::boxcox(data$TSH, lambda = seq(-10, 10, 0.1))
  data$TSH = EnvStats::boxcoxTransform(data$TSH, tsh$lambda[which.max(tsh$objective)])
  
  t3 = EnvStats::boxcox(data$T3, lambda = seq(-10, 10, 0.1))
  data$T3 = EnvStats::boxcoxTransform(data$T3, t3$lambda[which.max(t3$objective)])
  
  tt4 = EnvStats::boxcox(data$TT4, lambda = seq(-10, 10, 0.1))
  data$TT4 = EnvStats::boxcoxTransform(data$TT4, tt4$lambda[which.max(tt4$objective)])
  
  t4u = EnvStats::boxcox(data$T4U, lambda = seq(-10, 10, 0.1))
  data$T4U = EnvStats::boxcoxTransform(data$T4U, t4u$lambda[which.max(t4u$objective)])
  
  fti = EnvStats::boxcox(data$FTI, lambda = seq(-10, 10, 0.1))
  data$FTI = EnvStats::boxcoxTransform(data$FTI, fti$lambda[which.max(fti$objective)])
  
  data = mice::complete(mice::mice(data, print = FALSE), method = 'pmm')
  
  data = as.data.frame(mltools::one_hot(as.data.table(data), cols = "referral_source"))

  for(i in 1:(ncol(data))) {
    if(is.factor(data[, i])) {
      data[, i] = as.numeric(data[, i])
    }
  }
  
  data
}

data = OpenML::getOMLDataSet(38)$data
data$Class = as.numeric(data$Class)-1
train = read.csv2("https://raw.githubusercontent.com/mini-pw/2020L-WarsztatyBadawcze-InzynieriaCech/master/PracaDomowa1/indeksy_treningowe.txt",
                  sep = ' ')[,1]

data_train = data[train,]
data_test = data[-train,]

data_train = preprocess(data_train)
data_test = preprocess(data_test)
# 
# 
# # # ranger
# library(ranger)
# 
# 
# #black_box = ranger(Class~., data=data_train, num.trees = 10000)
# data_train_factor = data_train
# data_train_factor$Class = as.factor(data_train_factor$Class)
# black_box = mlr::makeLearner('classif.ranger', predict.type = 'prob')
# 
# result = cross_val_score2(data_train_factor, black_box, 5)
# 
# data_test_factor = data_test
# data_test_factor$Class = as.factor(data_test_factor$Class)
# 
# train_task = makeClassifTask(data=data_train_factor, target='Class')
# test_task = makeClassifTask(data=data_test_factor, target='Class')
# set.seed(77)
# trained = train(black_box, train_task)
# probs = predict(trained, test_task)$data$prob.1
# 
# fg = probs[data_test$Class == 1]
# bg = probs[data_test$Class == 0]
# 
# library(PRROC)
# # ROC Curve    
# roc <- roc.curve(scores.class0 = fg, scores.class1 = bg, curve = T)
# plot(roc)
# 
# # PR Curve
# pr <- pr.curve(scores.class0 = fg, scores.class1 = bg, curve = T)
# plot(pr)
# 
# # library(DALEX)
# # exp = explain(black_box, data_train[,-25],data_train$Class)
# # library(ingredients)
# # acc = ingredients::accumulated_dependency(exp)
# # plot(acc)
# # 
# # fi = ingredients::feature_importance(exp)
# # plot(fi)
# # 
# # x = predict(black_box, data_train)
# 
# # model
options(warn=-1)
data_train_mod = data_train
#result = cross_val_score(data_train_mod, 5)

data_train_mod$T3_sq = data_train_mod$T3 ^ 2
#result = cross_val_score(data_train_mod, 5)

data_train_mod$TT4_sq = data_train_mod$TT4 ^ 2
#result = cross_val_score(data_train_mod, 5)

data_train_mod$T4U_sq = data_train_mod$T4U ^ 2
#result = cross_val_score(data_train_mod, 5)

data_train_mod$T3_FTI = data_train_mod$T3/data_train_mod$FTI
#result = cross_val_score(data_train_mod, 5)
# 
# # TEST
# 
# model = glm(Class~., data=data_train_mod, family='binomial')
# 
data_test_mod = data_test
data_test_mod$T3_sq = data_test_mod$T3 ^ 2
data_test_mod$TT4_sq = data_test_mod$TT4 ^ 2
data_test_mod$T4U_sq = data_test_mod$T4U ^ 2
data_test_mod$T3_FTI = data_test_mod$T3/data_test_mod$FTI
# 
# probs = predict(model, newdata = data_test_mod, type = "response")
# 
# fg = probs[data_test$Class == 1]
# bg = probs[data_test$Class == 0]
# 
# library(PRROC)
# # ROC Curve    
# roc <- roc.curve(scores.class0 = fg, scores.class1 = bg, curve = T)
# plot(roc)
# 
# # PR Curve
# pr <- pr.curve(scores.class0 = fg, scores.class1 = bg, curve = T)
# plot(pr)
# 
# 
# 
# 
# 
# library(rpart)
# library(mlr)
# model = rpart(Class ~., data=data_train_mod, method='class')
# probs = predict(model, newdata = data_test_mod, type = "prob")[,2]
# 
# fg = probs[data_test$Class == 1]
# bg = probs[data_test$Class == 0]
# 
# # ROC Curve    
# roc <- roc.curve(scores.class0 = fg, scores.class1 = bg, curve = T)
# plot(roc)
# 
# # PR Curve
# pr <- pr.curve(scores.class0 = fg, scores.class1 = bg, curve = T)
# plot(pr)
# 
# 
# ###
# data_train_mod$Class = as.factor(data_train_mod$Class)
# task = mlr::makeClassifTask(data=data_train_mod, target = 'Class')
# model = mlr::makeLearner('classif.rpart', predict.type = 'prob')
# params = makeParamSet( 
#   makeDiscreteParam("minsplit", values=seq(5,10,1)), makeDiscreteParam("minbucket", values=seq(round(5/3,0), round(10/3,0), 1)), 
#   makeNumericParam("cp", lower = 0.01, upper = 0.05), makeDiscreteParam("maxcompete", values=6), makeDiscreteParam("usesurrogate", values=0), makeDiscreteParam("maxdepth", values=10) )
# ctrl = makeTuneControlGrid()
# rdesc = makeResampleDesc("CV", iters = 5L, stratify=TRUE)
# set.seed(77) 
# dt_tuneparam <- tuneParams(learner=model, 
#                             resampling=rdesc, 
#                             measures=list(tpr,auc, fnr, mmce, tnr, setAggregation(tpr, test.sd)), 
#                             par.set=params, 
#                             control=ctrl, 
#                             task=task, 
#                             show.info = TRUE)
# 
# dt_tuneparam$x
# model = mlr::makeLearner('classif.rpart', predict.type = 'prob', par.vals = dt_tuneparam$x)
# model = train(model, task)
# data_test_mod$Class = as.factor(data_test_mod$Class)
# task_test = mlr::makeClassifTask(data=data_test_mod, target = 'Class')
# probs = predict(model, task)$data$prob.1
# fg = probs[data_test$Class == 0]
# bg = probs[data_test$Class == 1]
# 
# # ROC Curve    
# roc <- roc.curve(scores.class0 = fg, scores.class1 = bg, curve = T)
# plot(roc)
# 
# # PR Curve
# pr <- pr.curve(scores.class0 = fg, scores.class1 = bg, curve = T)
# plot(pr)
# 
# 
# result = cross_val_score2(data_train_mod, model, 5)
