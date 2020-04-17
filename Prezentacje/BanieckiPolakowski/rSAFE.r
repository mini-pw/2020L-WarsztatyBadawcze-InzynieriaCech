library(rSAFE)
library(randomForest)
library(DALEX)

set.seed(997)

### Basic random forest model
model_rf1 <- randomForest(m2.price ~ construction.year + surface + floor + no.rooms + district, data = apartments)
explainer_rf1 <- explain(model_rf1, data = apartmentsTest[1:3000, 2:6], y = apartmentsTest[1:3000, 1], 
                         label = "Base randomForest", verbose = FALSE)

safe_extractor_rf1 <- safe_extraction(explainer_rf1, penalty = 25, verbose = FALSE)

### Plotting
plot(safe_extractor_rf1, variable = "construction.year") ### Changepoints detected with PELT algorithm
plot(safe_extractor_rf1, variable = "district")

### Data transforming
data_transformed <- safely_transform_data(safe_extractor_rf1, apartmentsTest[3001:6000,], verbose = FALSE)
head(data_transformed) ### New wild data appeared!

### Selecting best variables
vars <- safely_select_variables(safe_extractor_rf1, data_transformed, which_y = "m2.price", verbose = FALSE)

data_transformed <- data_transformed[, c("m2.price", vars)]
data_transformed_test <- safely_transform_data(safe_extractor_rf1, apartmentsTest[6001:9000,], verbose = FALSE)
data_transformed_test <- data_transformed_test[, c("m2.price", vars)]

### Basic linear model
model_lm1 <- lm(m2.price ~ ., data = apartments)
explainer_lm1 <- explain(model_lm1, data = apartmentsTest[1:3000, 2:6], y = apartmentsTest[1:3000, 1], 
                         label = "Base LM", verbose = FALSE)

### SAFE linear model
model_lm2 <- lm(m2.price ~ ., data = data_transformed)
explainer_lm2 <- explain(model_lm2, data = data_transformed_test, y = apartmentsTest[6001:9000, 1], 
                         label = "SAFE LM", verbose = FALSE)

mp_rf1 <- model_performance(explainer_rf1)
mp_lm1 <- model_performance(explainer_lm1)
mp_lm2 <- model_performance(explainer_lm2)

plot(mp_lm1, mp_rf1, mp_lm2, geom = "boxplot")
