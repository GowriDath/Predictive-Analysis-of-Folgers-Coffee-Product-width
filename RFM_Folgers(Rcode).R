# Install release version from CRAN
install.packages("rfm")

# Install development version from GitHub
# install.packages("devtools")

devtools::install_github("rsquaredacademy/rfm")

dataset2<-read.csv("C:\\Users\\gowri\\Downloads\\data.csv")
analysis_date <- lubridate::as_date('2001-12-25')



dataset2$Customer_id=dataset$ï..PANID
#dataset$most_recent_visit=as.Date(dataset$most_recent_visit, format = "%Y-%M-%D")

head(dataset2)
dataset=dataset2[grep("FOLGERS",dataset2$L5),]

dataset=dataset[dataset$L2=="GROUND COFFEE", ]


segments
# Set Analysis Date
#analysisDate <- "12/25/2001"
#analysisDate <- as.Date(analysisDate, format = "%Y-%m-%d")


dataset$Date <- dmy(dataset$most_recent_visit)
#as.Date(dataset$most_recent_visit, format="%Y-%m-%d")
dataset$datediff = as.numeric(difftime(analysis_date,dataset$Date, units = "days"))
rfm_result <- rfm_table_customer(dataset, PANID, units,
                                 recency_days, revenue, analysis_date)
#rfm_result
# dataset1 is the data for rfm function with only 4 necessary columns
dataset1=data.frame(dataset$Customer_id, dataset$UNITS, dataset$Date, dataset$DOLLARS)

#Frequency Calculation
frequency = function(data){
  aggregate(Date ~ Customer_id, data[,c(3,1)] , length)
}

#freq <- frequency(data_partnership)

#Recency Calculation
recency = function(data){
  aggregate(Date ~ Customer_id, data , min)
}



#rec <- recency(data_partnership)



#Monetary calculation
monetary = function(data){
  aggregate(Sales ~ Customer_id, data[,c(4,1)] , sum)
}



#mon <- monetary(data_partnership)



#Calculating scores



score = function(scoreData){
  
  maxQuartile = length(unique(scoreData))
  
  if (maxQuartile > 5){
    maxQuartile = 5
  }
  lowerLimit = (5 - maxQuartile) + 1
  scoreLabel = as.character(cut(scoreData,
                                breaks = c(quantile(unique(scoreData),probs= seq(0,1,length.out = maxQuartile + 1))),
                                labels = seq(lowerLimit,5),
                                include.lowest = TRUE))
  as.numeric(scoreLabel)
}



# Calculating Recency, Frequency and Monetary values for each customer
Recency=recency(dataset)
Frequency=frequency(dataset1)
Monetary=monetary(dataset1)




rfm_data = cbind(Recency, Frequency, Monetary)
names(rfm_data)[2] = "Recency"



#######
names(dataset1)[1] = "Customer_id"
names(dataset1)[2] = "Units"
names(dataset1)[3] = "Date"
names(dataset1)[4] = "Sales"
rfm_result <- rfm_table_order(dataset1, Customer_id, Date, Sales, analysis_date)


#display the table
rfm_result

####

#Heat map

rfm_heatmap(rfm_result)

rfm_bar_chart(rfm_result)

rfm_order_dist(rfm_result)
rfm_rm_plot(rfm_result)


rfm_histograms(rfm_result)

segment_names <- c("Champions", "Loyal Customers", "Potential Loyalist",
                   "New Customers", "Promising", "Need Attention", "About To Sleep",
                   "At Risk", "Can't Lose Them", "Lost")

recency_lower <- c(4, 2, 3, 4, 3, 2, 2, 1, 1, 1)
recency_upper <- c(5, 5, 5, 5, 4, 3, 3, 2, 1, 2)
frequency_lower <- c(4, 3, 1, 1, 1, 2, 1, 2, 4, 1)
frequency_upper <- c(5, 5, 3, 1, 1, 3, 2, 5, 5, 2)
monetary_lower <- c(4, 3, 1, 1, 1, 2, 1, 2, 4, 1)
monetary_upper <- c(5, 5, 3, 1, 1, 3, 2, 5, 5, 2)

segments=rfm_segment(rfm_result, segment_names, recency_lower, recency_upper,
            frequency_lower, frequency_upper, monetary_lower, monetary_upper)

rfm_plot_median_recency(segments)
rfm_plot_median_frequency(segments)
rfm_plot_median_monetary(segments)
rfm_fm_plot(rfm_result)
rfm_rf_plot(rfm_result)
hist(rfm_result$)


  
data = data[order(data$RFM_Score, decreasing = TRUE),]
head(data)
tail(data)

#results<-rfm_result

results<-as.data.frame(rfm_result)

write.csv(rfm_result, "rfm_L.csv")
rfm_heatmap(rfm_result)