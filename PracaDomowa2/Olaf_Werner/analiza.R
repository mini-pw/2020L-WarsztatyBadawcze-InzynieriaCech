library(dplyr)
library(readr)
library(DataExplorer)
library(mlr)
library(e1071)
#wczytanie danych
sick <- read_csv("dataset_38_sick.csv")

sick1<-sick %>%
  mutate_if(is.character, list(~na_if(., "?")))

sick2<-type_convert(sick1)

sick2<-DataExplorer::drop_columns(sick2,c("TBG","hypopituitary"))

sick2<-sick2 %>% mutate_if(is.character,as.factor)
sick2$Class<-sick2$Class=="sick"
sick2<-sick2 %>% mutate_if(is.logical,as.factor)

DataExplorer::plot_missing(sick2)

#miara AUPRC 
library(PRROC)

AUPRC2<-function(task, model, pred, feats, extra.args){
  fg<-pred$data[pred$data$truth=="TRUE",]$prob.TRUE
  bg<-pred$data[pred$data$truth=="FALSE",]$prob.TRUE
  pr <- pr.curve(scores.class0 = fg, scores.class1 = bg, curve = T)
  pr$auc.integral
}
AUPRC<-makeMeasure(id = "auprc", minimize = FALSE,
                   properties = c("classif", "req.pred", "req.truth"), best = 1, worst = 0, fun = AUPRC2)


#podzial na testowy i treningowy zgodnie z plikiem
train_index<-read_table2("indeksy_treningowe.txt")
train_index<-train_index$y

train_sick<-sick2[train_index,]
test_sick<-sick2[-train_index,]

# Random Forest
opt<-mlr::listLearners()
opt<-opt[opt$missings==TRUE & opt$installed==TRUE & opt$type=="classif" ,]

task<-makeClassifTask(data = train_sick, target = "Class")
rf_learner<-makeLearner("classif.cforest", predict.type = "prob")

fv = generateFilterValuesData(task, method = "FSelectorRcpp_information.gain")
rdesc = makeResampleDesc("CV", iters = 5)
task = filterFeatures(task, fval = fv, perc = 0.9)

# Calculate the performance
r = resample(rf_learner, task, rdesc, measures = list(mlr::auc, AUPRC))

rf_model <- train(rf_learner, task)
prediction <- predict(rf_model, newdata = test_sick)

df = generateThreshVsPerfData(prediction, measures = list(fpr, tpr, mmce))
plotROCCurves(df)
mlr::performance(prediction,list(mlr::auc,AUPRC))


# Calculate the performance
fv = generateFilterValuesData(task, method = "FSelectorRcpp_information.gain")

sick3 %>% filter_all(any_vars(is.na(.))) -> braki

sick4<-tidyr::drop_na(sick3)

treat<-vtreat::mkCrossFrameCExperiment(train_sick,varlist = colnames(train_sick)[-1],outcomename = "Class",outcometarget = "TRUE")

sick5<-vtreat::prepare(treat$treatments,sick3[-1])

treat$treatments$scoreFrame$code=="clean"

#rpart
task<-makeClassifTask(data = train_sick, target = "Class")
rpart_learner<-makeLearner("classif.rpart", predict.type = "prob")
fv = generateFilterValuesData(task, method = "FSelectorRcpp_information.gain")
rdesc = makeResampleDesc("CV", iters = 5)
clean_task = filterFeatures(task, fval = fv, perc = 0.5)

r = resample(rpart_learner, clean_task, rdesc, measures = list(mlr::auc, AUPRC))

rpart_model <- train(rpart_learner, clean_task)
prediction <- predict(rpart_model, newdata = test_sick)

df = generateThreshVsPerfData(prediction, measures = list(fpr, tpr, mmce))
plotROCCurves(df)
mlr::performance(prediction,list(mlr::auc,mlr::tnr,AUPRC))

rpart.plot::rpart.plot(rpart_model$learner.model)

#losowe
train_sick[train_sick$Class==TRUE,]

train_sick_t<-train_sick[train_sick$Class==TRUE,]

random<-sapply(1:27,FUN = function(x){train_sick_t[sample(1:184,500,replace = TRUE),x]})

random<-data.frame(random)

prediction <- predict(rf_model,newdata =  random)

response<-prediction$data$response

random$Class<-response
random<-rbind(random,train_sick)

#pewnosc klasy
#certainty<-((prediction$data$prob.0-0.5)^2)*4
certainty<-abs(prediction$data$prob.TRUE-0.5)*2

certainty<-c(certainty,rep(1,3016))

task<-makeClassifTask(data = random, target = "Class",weights = certainty)
#task_random<-makeClassifTask(data = random, target = "Class")

#rpart
#task<-makeClassifTask(data = random, target = "Class")
rpart_learner<-makeLearner("classif.rpart", predict.type = "prob")
fv = generateFilterValuesData(task, method = "FSelectorRcpp_information.gain")
rdesc = makeResampleDesc("CV", iters = 5)
clean_task = filterFeatures(task, fval = fv, perc = 0.8)

r = resample(rpart_learner, clean_task, rdesc, measures = list(mlr::auc, AUPRC))

rpart_model <- train(rpart_learner, clean_task)
prediction <- predict(rpart_model, newdata = test_sick)

df = generateThreshVsPerfData(prediction, measures = list(fpr, tpr, mmce))
plotROCCurves(df)
mlr::performance(prediction,list(mlr::auc,mlr::tnr,AUPRC))

rpart.plot::rpart.plot(rpart_model$learner.model,roundint = FALSE)

#hyper parameters

learner<-makeLearner("classif.rpart", predict.type = "prob")
task<-makeClassifTask(data = random, target = "Class",weights = certainty)

dt_param <- makeParamSet(
  makeDiscreteParam("minsplit", values=seq(5,10,1)), makeDiscreteParam("minbucket", values=seq(round(5/3,0), round(10/3,0), 1)),
  makeNumericParam("cp", lower = 0.01, upper = 0.05), makeDiscreteParam("maxcompete", values=6), makeDiscreteParam("usesurrogate", values=0),
  makeDiscreteParam("maxdepth", values=5) )

#nie ma roznicy
ctrl = makeTuneControlGrid()
rdesc = makeResampleDesc("CV", iters = 5L, stratify=TRUE)
(dt_tuneparam <- tuneParams(learner=learner,
                            resampling=rdesc,
                            measures=list(mlr::acc, AUPRC),
                            par.set=dt_param,
                            control=ctrl,
                            task=task,
                            show.info = TRUE) )

dtree <- setHyperPars(learner, par.vals = dt_tuneparam$x)
dtree_train <- train(learner=dtree, task=task)
prediction <- predict(dtree_train, newdata = test_sick)

df = generateThreshVsPerfData(prediction, measures = list(fpr, tpr, mmce))
plotROCCurves(df)
mlr::performance(prediction,list(mlr::auc,AUPRC))

rpart.plot::rpart.plot(dtree_train$learner.model,roundint = FALSE)


library(ggplot2)

ggplot(data = r$measures.test,aes(x=auc))+geom_boxplot()

temp<-r$measures.test

temp
temp2<-temp$auc

c(temp$auc,temp$auprc)

temp2<-tibble(score=c(temp$auc,temp$auprc),measure=c(rep("auc",5),rep("auprc",5)))

ggplot(data = temp2,aes(x=score),group_by=measure)+geom_boxplot()


data_frame(score=score_rpart_random,type=c("auc.cross","auprc.cross","auc.test","auprc.test"))
  



