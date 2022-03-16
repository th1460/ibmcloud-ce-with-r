library(plumber)

#* @apiTitle Prediction Survived in Titanic Disaster

#* Return the prediction survived
#* @param sex Sex
#* @param pclass Class
#* @get /predict
function(sex, pclass) {
  
  board <- pins::board_s3(bucket = Sys.getenv("COS_BUCKET"), 
                          region = Sys.getenv("COS_REGION"), 
                          access_key = Sys.getenv("COS_ACCESS_KEY_ID"),
                          secret_access_key = Sys.getenv("COS_SECRET_ACCESS_KEY"),
                          endpoint = Sys.getenv("COS_ENDPOINT"))
  
  model <- board |> pins::pin_read("my-model")
  input <- data.frame(Sex = sex, Pclass = pclass)
  pred <- tidypredict::tidypredict_to_column(input, model)
  
  return(pred)
  
}