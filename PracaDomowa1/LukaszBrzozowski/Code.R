library(OpenML)
library(plyr)
library(dplyr)
library(ggplot2)
library(dataMaid)
library(mlr)
library(glmnet)
library(PRROC)
library(DALEX)
library(rpart)
library(tidyverse)
library(caret)
library(DataExplorer)
library(AUC)
library(mlrMBO)
#Pobieranie danych
# dat <- OpenML::getOMLDataSet(data.id = 38L)$data
# 
# ix <- read.csv("probix.txt", header = TRUE, sep = " ")
# ixes <- ix[, 1]
# datTr <- dat[ixes, ]
# datTest <- dat[-ixes, ]
# write.csv(datTr, "train.csv")
# write.csv(datTest, "test.csv")


#Wczytanie danych

set.seed(1)
datTrain <- read.csv("train.csv")
datTest <- read.csv("test.csv")

datTrain <- datTrain %>% select(-X)
datTest <- datTest %>% select(-X)

#SEKCJA 1: OPIS ZBIORU DANYCH

#Pierwsza analiza zbioru danych:
#summarizeColumns(datTrain)

#Zamiana wartości kolumny celu na wartości 0, 1
datTrain$Class <- revalue(datTrain$Class, c("negative" = 0, "sick" = 1))
datTest$Class <- revalue(datTest$Class, c("negative" = 0, "sick" = 1))

datTrain$Class <- as.numeric(as.character(datTrain$Class))
datTest$Class <- as.numeric(as.character(datTest$Class))


#Wyrzucam kolumnę hypopituitary, ponieważ w zbiorze testowym są poziomy, które nie występują w zbiorze treningowym

datTrain <- datTrain %>% select(-hypopituitary)
datTest <- datTest %>% select(-hypopituitary)

#Wyrzucam kolumny TBG_measured i TBG, ponieważ nie wnoszą do danych żadnych nowych informacji

datTrain <- datTrain %>% select(-c(TBG_measured, TBG))
datTest <- datTest %>% select(-c(TBG_measured, TBG))

#Zmieniam wartości faktorów w pozostałych kolumnach na wartości numeryczne
for (i in c(3:16, 18, 20, 22, 24)){
  datTrain[, i] <- revalue(datTrain[, i], c("t" = 1, "f" = 0))
  datTest[, i] <- revalue(datTest[, i], c("t" = 1, "f" = 0))
}
datTrain$referral_source <- revalue(datTrain$referral_source, c("SVHC" = 0, "SVHD" = 1, "STMW" = 2, "SVI" = 3, "other" = 4))
datTest$referral_source <- revalue(datTest$referral_source, c("SVHC" = 0, "SVHD" = 1, "STMW" = 2, "SVI" = 3, "other" = 4))
datTrain$sex <- revalue(datTrain$sex, c("M" = 1, "F" = 0))
datTest$sex <- revalue(datTest$sex, c("M" = 1, "F" = 0))

# Utworzenie miary auprc dla mlr

auprc <- mlr::makeMeasure(id = "auprc",
                          minimize = FALSE,
                          properties = c("classif", "prob"),
                          fun = function(task, model, pred, feats, extra.args){
                            probs <- getPredictionProbabilities(pred)
                            fg <- probs[pred$data$truth == 1]
                            bg <- probs[pred$data$truth == 0]
                            pr <- pr.curve(scores.class0 = fg, scores.class1 = bg, curve = T)
                            pr$auc.integral
                          })

#SEKCJA 2: PIERWSZY MODEL

datTrainF <- datTrain
datTestF <- datTest
datTrainF$Class <- factor(datTrain$Class)
datTestF$Class <- factor(datTest$Class)

tsk <- makeClassifTask(data = datTrainF, target = "Class", positive = "1")
lrn <- makeLearner("classif.rpart", predict.type = "prob")
resample(lrn, tsk, cv5, list(mlr::auc, auprc))
#Aggregated Result: auc.test.mean=0.9605255,auprc.test.mean=0.8736800

#Na zbiorze testowym
# m <- mlr::train(lrn, tsk)
# 
# pred <- predict(m, newdata = datTestF)
# prob <- getPredictionProbabilities(pred)
# 
# fg <- prob[datTestF[,"Class"] == 1]
# bg <- prob[datTestF[,"Class"] == 0]
# pr <- pr.curve(scores.class0 = fg, scores.class1 = bg, curve = T)
# roc <- roc.curve(scores.class0 = fg, scores.class1 = bg, curve = T)
# pr$auc.integral
# plot(pr)
# roc$auc
# plot(roc)

#SEKCJA 3: WYBÓR ZMIENNYCH

validIX <- datTrainF$Class %>% createDataPartition(p = 0.8, list = FALSE)

train <- datTrainF[validIX,]
test <- datTrainF[-validIX,]

rp <- rpart(Class~., data = train, model = TRUE, )
pred <- predict(rp, test)

s <- summary(rp)

s$variable.importance
nm <- names(s$variable.importance[1:9])
nm[10] <- "Class"
datTrainN <- datTrainF[,nm]
datTestN <- datTestF[, nm]

tsk <- makeClassifTask(data = datTrainN, target = "Class", positive = "1")
lrn <- makeLearner("classif.rpart", predict.type = "prob")
resample(lrn, tsk, cv5, list(mlr::auc, auprc))
#Aggregated Result: auc.test.mean=0.9580530,auprc.test.mean=0.8761260

#Na zbiorze testowym

# m <- mlr::train(lrn, tsk)
# 
# pred <- predict(m, newdata = datTestN)
# prob <- getPredictionProbabilities(pred)
# 
# fg <- prob[datTestN[,"Class"] == 1]
# bg <- prob[datTestN[,"Class"] == 0]
# pr <- pr.curve(scores.class0 = fg, scores.class1 = bg, curve = T)
# roc <- roc.curve(scores.class0 = fg, scores.class1 = bg, curve = T)
# pr$auc.integral
# plot(pr)
# roc$auc
# plot(roc)

#SEKCJA 4: IMPUTACJA DANYCH
#Od tej chwili pracujemy tylko na nowym zbiorze danych z obciętymi kolumnami
##Imputacja standardowa
datTrainI <- impute(datTrainN, classes = list(numeric = imputeMean(), factor = imputeMode()))$data

tsk <- makeClassifTask(data = datTrainI, target = "Class", positive = "1")
lrn <- makeLearner("classif.rpart", predict.type = "prob")
resample(lrn, tsk, cv5, list(mlr::auc, auprc))
#Aggregated Result: auc.test.mean=0.9556092,auprc.test.mean=0.8740979

##Imputacja lasami
genData <- function(dat, name){
  datToImpute <- dat[is.na(dat[name]),]
  datFull <- dat[!is.na(dat[name]),]
  n <- nrow(datFull)
  
  
  if(class(unlist(c(datFull[name]))) == "factor"){
    print("Class: factor")
    tsk <- makeClassifTask(id = name, datFull, name, fixup.data = "no", check.data = FALSE)
    lr <- makeLearner("classif.rpart")
  }else{
    print("Class: numeric")
    tsk <- makeRegrTask(id = name, datFull, name, fixup.data = "no",check.data = FALSE)
    lr <- makeLearner("regr.rpart")
  }
  model <- mlr::train(lr, tsk)
  pred <- as.data.frame(predict(model, newdata = datToImpute %>% select(-name)))
  colnames(pred) <- c(name)
  nd <- cbind(datToImpute %>% select(-name), pred)
  nd <- nd[colnames(datFull)]
  rbind(datFull, nd)
}


ndat <- datTrainN
for(i in colnames(datTrainN)){
  if(any(is.na(datTrainN[i]))){
    print(i)
    ndat <- genData(ndat, i)
  }
}
datTrainI <- ndat
tsk <- makeClassifTask(data = ndat, target = "Class", positive = "1")
lrn <- makeLearner("classif.rpart", predict.type = "prob")
resample(lrn, tsk, cv5, list(mlr::auc, auprc))


#Aggregated Result: auc.test.mean=0.9640868,auprc.test.mean=0.8860113

#Na zbiorze testowym
# m <- mlr::train(lrn, tsk)
# 
# pred <- predict(m, newdata = datTestN)
# prob <- getPredictionProbabilities(pred)
# 
# 
# fg <- prob[datTestN[,"Class"] == 1]
# bg <- prob[datTestN[,"Class"] == 0]
# pr <- pr.curve(scores.class0 = fg, scores.class1 = bg, curve = T)
# roc <- roc.curve(scores.class0 = fg, scores.class1 = bg, curve = T)
# pr$auc.integral
# plot(pr)
# roc$auc
# plot(roc)

#SEKCJA 5: DYSKRETYZACJA ZMIENNYCH
#zmiennych numerycznych jest mało, więc z palca zmieniałem wartości i zmienne - nic nie przyniosło poprawy
datTrainD <- datTrainI
datTrainD$age <- discretize(datTrainD$age, breaks = 5, labels = c(0, 1, 2, 3, 4))

tsk <- makeClassifTask(data = datTrainD, target = "Class", positive = "1")
lrn <- makeLearner("classif.rpart", predict.type = "prob")
resample(lrn, tsk, cv5, list(mlr::auc, auprc))
#Aggregated Result: auc.test.mean=0.9544633,auprc.test.mean=0.8567226

#SEKCJA 6: Tuning hiperparametrów

iters = 100
par.set = makeParamSet(
  makeIntegerParam("minsplit", lower = 1, upper = 30),
  makeNumericParam("cp", lower = 0, upper = 1),
  makeIntegerParam("maxcompete", lower = 0, upper = 10),
  makeDiscreteParam("usesurrogate", values = c(0, 1, 2)),
  makeIntegerParam("maxdepth", lower = 1, upper = 30)
)

validIX <- datTrainI$Class %>% createDataPartition(p = 0.8, list = FALSE)

train <- datTrainI[validIX,]
test <- datTrainI[-validIX,]

tsk <- makeClassifTask(data = train, target = "Class", positive = "1")

rp <- makeSingleObjectiveFunction(name = "rpart.tuning",
                                  fn = function(x) {
                                    lrn <- makeLearner("classif.rpart", par.vals = x, predict.type = "prob")
                                    m <- mlr::train(lrn, tsk)
                                    
                                    pred <- predict(m, newdata = test)
                                    prob <- getPredictionProbabilities(pred)
                                    
                                    fg <- prob[test[,"Class"] == 1]
                                    bg <- prob[test[,"Class"] == 0]
                                    pr <- pr.curve(scores.class0 = fg, scores.class1 = bg, curve = F)
                                    pr$auc.integral
                                  },
                                  par.set = par.set,
                                  noisy = TRUE,
                                  has.simple.signature = FALSE,
                                  minimize = FALSE
)
ctrl = makeMBOControl()
ctrl = setMBOControlTermination(ctrl, iters = iters)
res = mbo(rp, control = ctrl, show.info = TRUE)
res$x

lrnMBO <- makeLearner("classif.rpart", par.vals = res$x, predict.type = "prob")

tsk <- makeClassifTask(data = datTrainI, target = "Class", positive = "1")
resample(lrnMBO, tsk, cv5, list(mlr::auc, auprc))
#Aggregated Result: auc.test.mean=0.9384173,auprc.test.mean=0.8393369

m <- mlr::train(lrnMBO, tsk)

pred <- predict(m, newdata = datTestN)
prob <- getPredictionProbabilities(pred)


fg <- prob[datTestN[,"Class"] == 1]
bg <- prob[datTestN[,"Class"] == 0]
pr <- pr.curve(scores.class0 = fg, scores.class1 = bg, curve = T)
roc <- roc.curve(scores.class0 = fg, scores.class1 = bg, curve = T)
pr$auc.integral
plot(pr)
roc$auc
plot(roc)

#SEKCJA 7: drzewo regresyjne
set.seed(1)

auprcR <- mlr::makeMeasure(id = "auprcR",
                          minimize = FALSE,
                          properties = c("regr", "respons"),
                          fun = function(task, model, pred, feats, extra.args){
                            probs <- pred$data$response
                            fg <- pred$data$response[pred$data$truth == 1]
                            bg <- pred$data$response[pred$data$truth == 0]
                            pr <- pr.curve(scores.class0 = fg, scores.class1 = bg, curve = F)
                            pr$auc.integral
                          })

iters = 30
par.set = makeParamSet(
  makeIntegerParam("minsplit", lower = 1, upper = 30),
  makeNumericParam("cp", lower = 0, upper = 1),
  makeIntegerParam("maxcompete", lower = 0, upper = 10),
  makeDiscreteParam("usesurrogate", values = c(0, 1, 2)),
  makeIntegerParam("maxdepth", lower = 1, upper = 30)
)

tsk <- makeRegrTask(id = "rpartR", data = datTrain, target = "Class")
rp <- makeSingleObjectiveFunction(name = "rpart.tuning",
                                  fn = function(x) {
                                    lrn <- makeLearner("regr.rpart", par.vals = x, predict.type = "response")
                                    resample(lrn, tsk, cv3, measures = list(auprcR))$aggr
                                  },
                                  par.set = par.set,
                                  noisy = TRUE,
                                  has.simple.signature = FALSE,
                                  minimize = FALSE
)
ctrl = makeMBOControl()
ctrl = setMBOControlTermination(ctrl, iters = iters)
res = mbo(rp, control = ctrl, show.info = TRUE)
res$x

lrn <- makeLearner("regr.rpart", par.vals = res$x, predict.type = "response")
tsk <- makeRegrTask(id = "rpartR", data = datTrain, target = "Class")

model <- mlr::train(lrn, tsk)
pred <- predict(model, newdata = datTest)

resample(lrn, tsk, cv5, measures = list(auprcR))

fg <- pred$data$response[datTest[,"Class"] == 1]
bg <- pred$data$response[datTest[,"Class"] == 0]
pr <- pr.curve(scores.class0 = fg, scores.class1 = bg, curve = T)
pr$auc.integral
plot(pr)
roc <- roc.curve(scores.class0 = fg, scores.class1 = bg, curve = T)
roc$auc
plot(roc)
# > pr$auc.integral
# [1] 0.8750641
# > plot(pr)
# > roc <- roc.curve(scores.class0 = fg, scores.class1 = bg, curve = T)
# > roc$auc
# [1] 0.9247367
# > plot(roc)

set.seed(30)
lrn <- makeLearner("regr.rpart", predict.type = "response")
tsk <- makeRegrTask(id = "rpartR", data = datTrain, target = "Class")
model <- mlr::train(lrn, tsk)
pred <- predict(model, newdata = datTest)

fg <- pred$data$response[datTest[,"Class"] == 1]
bg <- pred$data$response[datTest[,"Class"] == 0]
pr <- pr.curve(scores.class0 = fg, scores.class1 = bg, curve = T)
pr$auc.integral
plot(pr)
roc <- roc.curve(scores.class0 = fg, scores.class1 = bg, curve = T)
roc$auc
plot(roc)
# [1] 0.9249696
# > plot(pr)
# > roc <- roc.curve(scores.class0 = fg, scores.class1 = bg, curve = T)
# > roc$auc
# [1] 0.9763377
# > plot(roc)

