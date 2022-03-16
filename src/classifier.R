# prepare data
train_data <-
  titanic::titanic_train |> 
  dplyr::select(Survived, Pclass, Sex) |> 
  dplyr::mutate(Sex = as.factor(Sex),
                Pclass = factor(Pclass, labels = c("1st", "2nd", "3rd")),
                Survived = factor(Survived, labels = c("Yes", "No")))

# fit model
lr_mod <- parsnip::logistic_reg() |> 
  parsnip::set_engine("glm")

lr_fit <- lr_mod |> 
  parsnip::fit(Survived ~ Sex + Pclass, data = train_data)

# save model on cloud object storage
saved_lr_fit <- tidypredict::parse_model(lr_fit)

board <- pins::board_s3(bucket = Sys.getenv("COS_BUCKET"), 
                        region = Sys.getenv("COS_REGION"), 
                        access_key = Sys.getenv("COS_ACCESS_KEY_ID"),
                        secret_access_key = Sys.getenv("COS_SECRET_ACCESS_KEY"),
                        endpoint = Sys.getenv("COS_ENDPOINT"))

board |> pins::pin_write(saved_lr_fit, name = "my-model")

# get results
"https://plumber.lnlpoiqaiyu.us-south.codeengine.appdomain.cloud/predict?sex=male&pclass=1st" |>
  httr::GET() |> 
  httr::content()

