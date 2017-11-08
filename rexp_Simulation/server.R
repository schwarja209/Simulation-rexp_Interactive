library(shiny)
library(dplyr)

# Define server logic required to generate the distribution plots
shinyServer(function(input, output) {
    
    lambda<-0.2 #assign default lambda
    mean_theory1<-1/lambda #find population/theoretical mean
    
    simulations<-reactive({ #a function that runs the simulations based on user inputs
        n<-input$sample.size #assign default number of from user input
        nsim1<-input$simulations #assign default number of simulations from user input
        
        set.seed(input$seed) #set seed for reproducibility from user input
        
        sim1<-matrix(data=rexp(n*nsim1,rate=lambda),nrow=nsim1,ncol=n) #create raw simulation matrix for rexp()
        sim1_mean<-data.frame(Mean=rowMeans(sim1)) #take mean of each simulation, and store in data frame
        sim1_mean<-mutate(sim1_mean,Index=row.names(sim1_mean))%>%select(Index,Mean) #tidy data frame
        
        return(sim1_mean)
    })
    
    means<-reactive({ #a function that calculates the sample mean
        sim1_mean<-simulations()
        mean_sample1<-mean(sim1_mean$Mean) #find sample mean
        
        return(mean_sample1)
    })
    
    variances<-reactive({ #a function that calculates the sample variance
        sim1_mean<-simulations()
        var_sample1<-var(sim1_mean$Mean) #find sample variance
        
        n<-input$sample.size #must recall sample input, since it's not global
        var_theory1<-(1/lambda)^2/n #find population/theoretical variance
        
        return(c(var_sample1,var_theory1))
    })
    
    output$mean<-renderText({ #generate demo mean output
        mean_sample1<-means()
        means<-paste0("Theoretical Mean: ",round(mean_theory1,3)," | Sample Mean: ",round(mean_sample1,3))
        
        return(means)
    })
    
    output$variance<-renderText({ #generate demo variance output
        var_sample1<-variances()[1]
        var_theory1<-variances()[2]
        variances<-paste0("Theoretical Variance: ",round(var_theory1,3)," | Sample Variance: ",round(var_sample1,3))
        
        return(variances)
    })
    
    output$confidence<-renderText({ #generate demo confidence interval output
        n<-input$sample.size #must recall sample input, since it's not global
        mean_sample1<-means()
        var_sample1<-variances()[1]
        conf95_sample1<-mean_sample1+c(-1,1)*qnorm(.975)*sqrt(var_sample1)/sqrt(n) #find 95% confidence intervals
        conf95s<-paste0("95% Confidence Interval from ",round(conf95_sample1[1],3),
                        " to ",round(conf95_sample1[2],3))
        
        return(conf95s)
    })
    
    makeData<-reactive({ #function to create alternate dataset from user selection
        sim1_mean<-simulations()
        userData<-brushedPoints(sim1_mean,input$brush1,xvar="Index",yvar="Mean")
        
        return(userData)
    })
    
    makeMeans<-reactive({ #function to create alternate sample mean
        userData<-makeData()
        
        if(nrow(userData)<2){ #if not enough points are selected, no mean
            return(NULL)
        }else{
            mean_sample2<-mean(userData$Mean) #find new sample mean
            return(mean_sample2)
        }
    })
    
    makeVariances<-reactive({ #function to create alternate sample variance
        userData<-makeData()
        
        if(nrow(userData)<2){ #if not enough points are selected, no variance
            return(NULL)
        }else{
            var_sample2<-var(userData$Mean) #find new sample variance
            return(var_sample2)
        }
    })
    
    output$userMean<-renderText({ #generate new mean output
        mean_sample2<-makeMeans()
        if(is.null(mean_sample2)){
            mean_sample2<-"Not enough points selected"
        }else{
            mean_sample2<-round(mean_sample2,3)
        }
        
        return(mean_sample2)
    })
    
    output$userVariance<-renderText({ #generate new variance output
        var_sample2<-makeVariances()
        if(is.null(var_sample2)){
            var_sample2<-"Not enough points selected"
        }else{
            var_sample2<-round(var_sample2,3)
        }
        
        return(var_sample2)
    })
    
    output$userConfidence<-renderText({ #generate new confidence interval output
        n<-input$sample.size #must recall sample input, since it's not global
        mean_sample2<-makeMeans()
        var_sample2<-makeVariances()
        
        if(is.null(mean_sample2)|is.null(var_sample2)){
            conf95s<-"Not enough points selected"
        }else{
            conf95_sample2<-mean_sample2+c(-1,1)*qnorm(.975)*sqrt(var_sample2)/sqrt(n) #find 95% confidence intervals
            conf95s<-paste0("95% Confidence Interval from ",round(conf95_sample2[1],3),
                            " to ",round(conf95_sample2[2],3))
        }
        
        return(conf95s)
    })
    
    output$userPlot<-renderPlot({ #generate a simple scatterplot of the simulation points
        sim1_mean<-simulations()
        mean_sample2<-makeMeans()
        
        plot(sim1_mean)
        
        if(input$means==TRUE){
            if(is.null(mean_sample2)){ #if user has selected points, draw a mean line based on their points
                mean_sample1<-means()
                abline(h=mean_sample1,col="orange",lwd=2) #print mean line on graph
            }else{
                abline(h=mean_sample2,col="orange",lwd=2)
            }
        }
    })
    
    output$histPlot<-renderPlot({ #generate histogram distribution plot for final CLT demo
        userData<-makeData()
        if(input$newData==FALSE|nrow(userData)<2){ #if user has selected new data, use that data
            sim1_mean<-simulations()
            mean_sample1<-means()
            var_sample1<-variances()[1]
            var_theory1<-variances()[2]
        }else{
            sim1_mean<-userData
            mean_sample1<-makeMeans()
            var_sample1<-makeVariances()
            var_theory1<-variances()[2]
        }
        
        #simulation with means
        hist(sim1_mean$Mean,breaks=100,freq=FALSE,main="",col="lightblue",xlab="Sample Means")
        
        if(input$variances==TRUE){
            x1<-seq(min(sim1_mean$Mean),max(sim1_mean$Mean),length=100) #create x spread for population density curve
            y1<-dnorm(x1,mean=mean_theory1,sd=sqrt(var_theory1)) #create y distribution for population density    
            
            lines(density(sim1_mean$Mean),col="orange",lwd=3) #print sample density curve
            lines(x1,y1,col="green",lwd=3)
            
            legend("topright",legend=c("Theoretical","Experimental"),col=c("green","orange"),lwd=2,box.lty=0)
        }
        
        if(input$means==TRUE){
            abline(v=mean_sample1,col="orange",lwd=2) #print mean lines on graph
            abline(v=mean_theory1,col="green",lwd=2)
            
            legend("topright",legend=c("Theoretical","Experimental"),col=c("green","orange"),lwd=2,box.lty=0)
        }
    })
})