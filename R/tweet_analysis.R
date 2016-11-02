library('jsonlite')
library('dplyr')
library('reshape2')
library('tm')

tweet = read.csv("Python/tweetdump.csv", colClasses = "character")
tweet = tweet[!duplicated(tweet$id_str),]


tweet$created_at_dt = as.POSIXct(strptime(tweet$created_at, "%a %b %d %H:%M:%S +0000 %Y"))
t <- strftime(tweet$created_at_dt, format="%H:%M:%S")
tweet$created_at_t = as.POSIXct(t, format="%H:%M:%S")
tweet$created_at_d = as.Date(tweet$created_at_dt)
tweet$user.created_at_dt =  as.POSIXct(strptime(tweet$user.created_at, "%a %b %d %H:%M:%S +0000 %Y"))
tweet$created_at <- NULL
tweet$user.created_at <- NULL

save(tweet, file="tweets.Rd")

tweet$user.utc_offset = as.numeric(tweet$user.utc_offset)
tweet$entities.hashtags <- sapply(tweet$entities.hashtags, tolower)


tweet_filter = tweet %>% filter( grepl("moneysupermarket", entities.hashtags) | 
                                         grepl("epicbuilder", entities.hashtags) |
                                         grepl("epicwolf", entities.hashtags) |
                                         grepl("epicdanceoff", entities.hashtags) |
                                         grepl("epicsquads", entities.hashtags) |
                                         grepl("epicstrut", entities.hashtags)
                                   )
#,                                         is_a_retweet == "NO")


all_hashtags = unlist(strsplit(paste(tweet$entities.hashtags, collapse = ":"),":"))
top_hashtags = as.data.frame(sort(table(all_hashtags),decreasing=TRUE)[1:1000])

top_users = as.data.frame(sort(table(tweet_filter$user.name)))

text =  Corpus(VectorSource(tolower(paste(tweet_filter$text, collapse = " "))))
text <- tm_map(text, removeNumbers)  
text = tm_map(text, removePunctuation)
text = tm_map(text, removeWords, stopwords("english")) 
text <- tm_map(text, stripWhitespace)   
text <- tm_map(text, PlainTextDocument)

dtm <- DocumentTermMatrix(text) 
tdm <- TermDocumentMatrix(text)   

findFreqTerms(dtm, lowfreq=50) 
freq <- sort(colSums(as.matrix(dtm)), decreasing=TRUE)   
wf <- data.frame(word=names(freq), freq=freq)[1:10,] 
p <- ggplot(subset(wf, freq>50), aes(word, freq))    
p <- p + geom_bar(stat="identity")   
p <- p + theme(axis.text.x=element_text(angle=45, hjust=1))   
p   


freq <- colSums(as.matrix(dtm))   

all_words = unlist(
  strsplit(
    tm_map(
    Corpus(tolower(
      paste(tweet_filter$text, collapse = " ")
      ))
    , removePunctuation)
    ," ")
  )
 
top_words = as.data.frame(sort(table(all_words)))


epicwolf <- tweet_filter %>% filter(grepl("epicwolf", entities.hashtags) ) %>% mutate(adv = "epicwolf")
epicbuilder <- tweet_filter %>% filter(grepl("epicbuilder", entities.hashtags) )  %>% mutate(adv = "epicbuilder")
epicdanceoff <- tweet_filter %>% filter(grepl("epicdanceoff", entities.hashtags) )  %>% mutate(adv = "epicdanceoff")
epicstrut <- tweet_filter %>% filter(grepl("epicstrut", entities.hashtags) )  %>% mutate(adv = "epicstrut")

epicadv <- rbind(epicwolf, epicbuilder, epicdanceoff, epicstrut)

ggplot(tweet, aes(x=created_at_d, group=1)) + 
  geom_freqpoly(bins=100)  +
  theme(axis.text.x = element_text(angle = 45, hjust = 1), legend.position ='none' )

ggplot(epicadv, aes(x=created_at_d, group=adv, colour = adv ,fill=adv)) + 
  geom_freqpoly(bins=100) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1), legend.position ='none' )

epicbuilder.plot = as.data.frame(table(epicbuilder$created_at_d))

hist(epicwolf$created_at_d, breaks = 30, freq = TRUE)
hist(epicbuilder$created_at_d, breaks = 30, freq = TRUE)
hist(epicdanceoff$created_at_d, breaks = 30, freq = TRUE)
hist(epicstrut$created_at_d, breaks = 30, freq = TRUE)
