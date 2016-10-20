
# This is the server logic for a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
#

library(shiny)
library(plotly)
library(DT)
library(dplyr)
library(jsonlite)

source("configparser.R")

CONFIG_FILE = "../../config/config.ini"
print(getwd())

configuration <<- Parse.INI(CONFIG_FILE)

shinyServer(function(input, output, session) {
  
  channels <<- names(configuration)
  channels <<- channels[channels != "DEFAULT"]
  
  output$ui_streams <- renderUI({
      selectInput("s_select_channel", label = "Select Channel", choices = channels)
  })
  
  output$channel_log <- renderPrint({
    channel = input$s_select_channel
    
    filename_path = configuration[['DEFAULT']]$tweeter_data_folder
    filename_pattern = paste0(configuration[[channel]]$output_file_prefix,".*log")
    logfile = sort(list.files(filename_path, pattern = filename_pattern),decreasing = TRUE)[1]
    
    if(!is.na(logfile)){
      text = readLines(paste0(filename_path,"/",logfile), warn = FALSE)
      split_text = rev(lapply(text, function(x) if (length(x) > 0) {unlist(splitInParts(x,120))}))[1:10]
      cat(unlist(split_text),sep="\n")
    }
    else
      cat("No log file found!")
  })
  
  output$channel_plot <- renderPlotly({
    print("Render plot!")
    channel = input$s_select_channel
    filename = paste0(configuration[['DEFAULT']]$tweeter_data_folder,"/",configuration[[channel]]$output_file_prefix,"stats.csv")
    
    tweets = read.csv(filename, colClasses = "character")
    tweets = tweets[!duplicated(tweets$id_str),]
    
    tweets$created_at_dt = as.POSIXct(strptime(tweets$created_at, "%a %b %d %H:%M:%S +0000 %Y"))
    tweets$created_at_d = as.Date(tweets$created_at_dt)
    tweets$created_at <- NULL
    
    hashtags = tolower(configuration[[channel]]$hashtags)
    
    if(is.null(tags))
      hashtags = ""
    else
      hashtags = unique(fromJSON(tolower(gsub('#','',hashtags))))
    
    tweets.plot = plot_ly( type = 'scatter', mode = 'lines') 
    
    for(hashtag in hashtags){
      tmp.plot = tweets %>% filter(grepl(hashtag, entities.hashtags) ) %>%
        group_by(created_at_d) %>% mutate(myhashtag = hashtag) %>% summarise(count = n())
      
      tweets.plot <- tweets.plot %>%
        add_trace(x=tmp.plot$created_at_d, y =tmp.plot$count, evaluate = TRUE ,  name=paste0(hashtag))
        #rbind(tweets.plot , tmp.plot)
    }
    
    tweets.plot <- tweets.plot %>% layout(                        # all of layout's properties: /r/reference/#layout
      title = paste0("Tweets ",channel), # layout's title: /r/reference/#layout-title
      xaxis = list(           # layout's xaxis is a named list. List of valid keys: /r/reference/#layout-xaxis
        title = "Time",      # xaxis's title: /r/reference/#layout-xaxis-title
        showgrid = T),       # xaxis's showgrid: /r/reference/#layout-xaxis-showgrid
      yaxis = list(           # layout's yaxis is a named list. List of valid keys: /r/reference/#layout-yaxis
        title = "Count")     # yaxis's title: /r/reference/#layout-yaxis-title
    )
    
    tweets.plot
    
  })
  
  output$ui_configurestream <- renderConfiguration(input, configuration)
  
  observeEvent(input$create_stream, {
    stream_name = input$new_stream_name
    
    if(stream_name %in% names(configuration)){
      print("Stream already exists")
    }else{
      new_configuration = list()
      new_configuration['active'] = FALSE
      configuration[[stream_name]] <<- new_configuration
      channels <<- names(configuration)
      channels <<- channels[channels != "DEFAULT"]
      output$ui_configurestream <- renderConfiguration(input, configuration)
      output$ui_streams <- renderUI({
        selectInput("s_select_channel", label = "Select Channel", choices = channels)
      })
    }
  })
  
  observeEvent(input$save_action, {
    # Get configuration

    for(channel in channels){
      print(paste0("Scanning channel: ", channel))
      
      active = ifelse(input[[paste0(channel,"_active")]]==TRUE,1,0)
      consumer_key = input[[paste0(channel,"_consumer_key")]]
      consumer_secret = input[[paste0(channel,"_consumer_secret")]]
      access_token = input[[paste0(channel,"_access_token")]]
      access_token_secret = input[[paste0(channel,"_access_token_secret")]]
      output_file_prefix = input[[paste0(channel,"_output_file_prefix")]]
      hashtags = toJSON(unlist(
        lapply(strsplit(input[[paste0(channel,"_hashtags")]],","), trimws)
        ))
      
      new_configuration = list()
      new_configuration['active'] = active
      if(nchar(consumer_key)>0){
        new_configuration['consumer_key'] = consumer_key
        print(consumer_key)
      }
      if(nchar(consumer_secret)>0){
        new_configuration['consumer_secret'] = consumer_secret
        print(consumer_secret)
      }
      if(nchar(access_token)>0){
        new_configuration['access_token'] = access_token
        print(access_token)
      }
      if(nchar(access_token_secret)>0){
        new_configuration['access_token_secret'] = access_token_secret
        print(access_token_secret)
      }
      if(nchar(output_file_prefix)>0){
        new_configuration['output_file_prefix'] = output_file_prefix
        print(output_file_prefix)
      }
      #if(nchar(hashtags)>0){
        new_configuration['hashtags'] = hashtags
        #print(hashtags)
      #}
      
      configuration[[channel]] <- new_configuration
      
    }
    
    Save.INI(configuration, CONFIG_FILE)
    print("Get Init and save")
    configuration <<- Parse.INI(CONFIG_FILE)
    output$ui_configurestream <- renderConfiguration(input, configuration)
  })
  
})


# 
#renderConfiguration(input, config.file)

renderConfiguration <- function(input, configuration){
  # Loop all the channels
  renderUI({
    channels = names(configuration)
    channels = channels[channels != "DEFAULT"]
    ret_output =  lapply(channels, function(i) {
      
      active = ifelse(configuration[[i]]$active=="1", TRUE, FALSE)
      consumer_key = configuration[[i]]$consumer_key
      consumer_secret = configuration[[i]]$consumer_secret
      access_token = configuration[[i]]$access_token
      access_token_secret = configuration[[i]]$access_token_secret
      output_file_prefix = configuration[[i]]$output_file_prefix
      tags = configuration[[i]]$hashtags
     
      status = ifelse(active, "success", "warning" )
      
      print("Load confffff")

      consumer_key = ifelse(is.null(consumer_key),"",consumer_key)
      consumer_secret = ifelse(is.null(consumer_secret),"",consumer_secret)
      access_token = ifelse(is.null(access_token),"",access_token)
      access_token_secret = ifelse(is.null(access_token_secret),"",access_token_secret)
      output_file_prefix = ifelse(is.null(output_file_prefix),"",output_file_prefix)
      if(is.null(tags))
         hashtags = ""
      else
         hashtags = fromJSON(tags)
      
      
      fluidRow(
        box(
          title = i, status = status, solidHeader = TRUE,
          collapsible = TRUE, collapsed = TRUE,
          checkboxInput(paste0(i,"_active"), label = "Active", value=active),
          textInput(paste0(i,"_consumer_key"), label = "Consumer Key", value=consumer_key),
          textInput(paste0(i,"_consumer_secret"), label = "Consumer Secret", value=consumer_secret),
          textInput(paste0(i,"_access_token"), label = "Access Token", value=access_token),
          textInput(paste0(i,"_access_token_secret"), label = "Access Token Secret", value=access_token_secret),
          textInput(paste0(i,"_output_file_prefix"), label = "Output Filename Prefix", value=output_file_prefix),
          textInput(paste0(i,"_hashtags"), label = "HashTags", value=paste(hashtags,collapse = ", "))
        )
      )
    }
    )
    
    ret_output
  })
}


splitInParts <- function(string, size){
  pat <- paste0('(?<=.{',size,'})')
  strsplit(string, pat, perl=TRUE)
}
