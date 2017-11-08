library(shiny)
library(dplyr)

# Define UI for application
shinyUI(fluidPage(
    
    # Application title
    titlePanel("Demonstrating the Central Limit Theorum in R"),
    
    # Sidebar with several inputs
    sidebarLayout(
        sidebarPanel(
            h3("Design Demonstration"),
            numericInput("seed","Pick a Random Number:",value=1987,min=-2147483647,max=2147483647,step=1),
            sliderInput("sample.size","Pick Number of Samples:",min=20,max=100,value=40),
            sliderInput("simulations","Pick Number of Simulations",min=100,max=10000,value=1000,step=100),
            checkboxInput("means","Graph Means?",value=TRUE),
            checkboxInput("variances","Graph Densities Curves?",value=TRUE),
            checkboxInput("newData","Graph Distribution of Your Own Data? (See 2nd Tab)",value=FALSE),
            submitButton("Run Simulations")
        ),
        
        # Two tabbed main panel area
        mainPanel(tabsetPanel(type="tabs",
                              #First tab is main simulation
                              tabPanel("Simulation Data",h3("Simulation Results"),plotOutput("histPlot"),
                                       h4("Mean Comparison: "),em(textOutput("mean")),br(),
                                       h4("Variance Comparison: "),em(textOutput("variance")),br(),
                                       h4("Confidence Interval: "),em(textOutput("confidence"))),
                              #Second tab is dataset selection, with an interactive graph
                              tabPanel("Make Your Own Data!",em(h3("Select Your Own Data Set From The Points Below")),
                                       plotOutput("userPlot",brush=brushOpts(id="brush1")),
                                       h4("Sample Mean of Your Data: "),em(textOutput("userMean")),br(),
                                       h4("Sample Variance of Your Data: "),em(textOutput("userVariance")),br(),
                                       h4("Confidence Interval for Your Data"),em(textOutput("userConfidence")))
        ))
    )
))
