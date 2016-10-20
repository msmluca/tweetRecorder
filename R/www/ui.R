
# This is the user-interface definition of a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
#

library(shiny)
library(shinydashboard)
library(shinyBS)
library(plotly)


# Main dashboard page ------
dashboardPage(skin = "purple",
              
              # Header -----------
              
              dashboardHeader(title = "Tweeter Streaming"),
              
              # Sidebar ----------- 
              
              dashboardSidebar(
                #sidebarMenu(
                  #menuItem("Configure Stream", tabName = "s_configurestream", icon = icon("line-chart")),
                  #menuItem("Monitor Stream", tabName = "s_monitoring", icon = icon("bar-chart")),
                  uiOutput("ui_streams" )
                #)
              ),
              
              # Body -----------------
              
              dashboardBody(
                tags$head(tags$style(
                  type = 'text/css',
                  '#test{ overflow-x: scroll; height:90vh !important; }'
                )),
                tabItems(
                  # Body menu --------------
                  tabItem(tabName = "s_configurestream",
                          fluidPage(
                      uiOutput("ui_configurestream"),
                      fluidRow(
                        textInput("new_stream_name", label = "Stream name", value=""),
                        actionButton("create_stream", label = "New Stream"),
                        actionButton("save_action", label = "Save Configuration")
                      )
                     )
                  ),
                  #uiOutput("ui_tab_streams_plot" )
                  tabItem(tabName = "s_monitoring",
                           plotlyOutput("channel_plot")
                  )
                  # uiOutput("ui_channels_plot")
                )
              )
)
