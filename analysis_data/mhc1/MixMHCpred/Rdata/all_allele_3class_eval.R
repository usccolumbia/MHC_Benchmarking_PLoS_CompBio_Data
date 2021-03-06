library(DiagTest3Grp)
setwd(getwd())

###List of alleles and methods
#methods = c("netmhc4", "netmhcpan3")
#methods = c("smm", "smmpmbec", "ann", "pickpocket", "consensus", "netmhcpan2.8", "netmhccons")
#methods = c("mhcflurry","mhcflurry_pan")
#methods = c("NetMHCpan4")
methods = c("MixMHCpred")
#allele_list <- read.table("../../CountLogStrip", sep="")
#write("Allele to be calculated:", stderr())
#print(allele_list[[1]])

### ANALYSIS ONE  ###
###This segment only used for calculating on summary data of each method
###Generate one summary table and VUS plots for every method
outputfile <- "3c_eval_allmethods_MixMHCpred.txt"
df <- data.frame(methods)
vus_col <- list()
vus_ci_col <- list()
Se_col <- list()
Sm_col <- list()
Sp_col <- list()
for (i in 1:length(methods)){
  method <- methods[i]
  file <- paste("../../", method, "/Rdata/summary.txt", sep="")
  #datafile <- read.table(file, col.names=c("idx","peptide","meas","pred"),sep=",", header= FALSE, comment.char="#")
  datafile <- read.table(file, sep=",",header=TRUE,comment.char="#",stringsAsFactor=F)  

  ###Set up the input data and classify into three classes
  data <- as.data.frame(datafile)
  headerline <- which (with(data,Peptide=="Peptide"))
  data <- data[-headerline,]
  Binding <- list()
  for (j in 1:length(data$meas_contin)){
    meas <- 1-log10(as.numeric(as.character(data$meas_contin)))/log10(50000.0)
    if (meas[j] > 0.638){
      Binding[j]="SB"
    } 
    else if (meas[j] > 0.426){
      Binding[j]="WB"
    } 
    else {
      Binding[j]="NB"
    }
  }
  data$binding <- Binding
  group <- data$binding
  ###Use affinity value###
  factor <- as.numeric(as.character(data$Max_score))
  x <- factor[group=="NB"]
  y <- factor[group=="WB"]
  z <- factor[group=="SB"]
  
  ###Calculate VUS, VUS_CI and Se
  #vus <- VUS(x,y,z,method="Normal",p=0,q=0,alpha=0.05)
  vus <- Normal.VUS(x,y,z,p=0,q=0,alpha=0.05)
  vus_col[i] <- vus$estimate
  vus_ci_col[i] <- (vus$estimate - vus$CI[1])
  ###Use affinity value###                    
  Se_col[i] <- Sp.Sm.Se(x,y,z,0.426,0.638)[3]
  Sm_col[i] <- Sp.Sm.Se(x,y,z,0.426,0.638)[2]
  Sp_col[i] <- Sp.Sm.Se(x,y,z,0.426,0.638)[1]
  ###Plot the data generated by VUS; only needed for summary data
  #pdf(paste(method,"_3c_eval.pdf"),width=8,height=4)
  #plot(vus)
  #dev.off()
}

###Write the final table
df$vus <- vus_col
df$vusci <- vus_ci_col
df$Se <- Se_col
df$Sp <- Sp_col
df$Sm <- Sm_col
write.table(as.matrix(df), outputfile, 
            col.names=c("Method", "VUS", "CI_L", "Se", "Sp", "Sm"), 
            row.names=F, append=T, sep="\t")

### ANALYSIS TWO  ###
###This part do calculation on individual allele
###Do calculation for each method and generate respective allele summary
#for (i in 1:length(methods)){
#  method <- methods[i]
#  outputfile <- paste(method, "_vus.txt", sep="")
#  df <- data.frame(allele_list[[1]])
#  vus_col <- list()
#  vus_ci_col <- list()
#  Se_col <- list()
#  
#  ###Inner loop on each allele; read allele data
#  for (j in 1:length(allele_list[[1]])){
#    allele <- allele_list[[1]][j]
#    file <- paste("../",method,"/Rdata/HLA-",allele,".txt", sep="")
#    if (file.exists(file)){
#       datafile <- read.table(file, col.names=c("idx","peptide","meas","pred"),sep=",", header= FALSE, comment.char="#")
#    }
#    else{
#      print(paste("file not exist for allele:", allele))
#      vus_col[j] <- NULL
#      Se_col[j] <- NULL
#      next
#    } 
#    
#    ###Set up the input data and classify into three classes
#    data <- data.frame(datafile)
#    #headerline <- which (with(data,peptide=="peptide"))
#    #data <- data[-headerline,]
#    Binding <- list()
#    for (k in 1:length(data$meas)){
#      if (as.numeric(as.character(data$meas[k])) > 0.638){
#        Binding[k]="SB"
#      } 
#      else if (as.numeric(as.character(data$meas[k])) > 0.426){
#        Binding[k]="WB"
#      } 
#      else {
#        Binding[k]="NB"
#      }
#    }
#    data$binding <- Binding
#    group <- data$binding
#    factor <- as.numeric(as.character(data$pred))
#    
#    ###Use affinity value###
#    #factor <- as.numeric(as.character(data$predict_rank))
#    x <- factor[group=="NB"]
#    y <- factor[group=="WB"]
#    z <- factor[group=="SB"]
#    
#    ###Calculate VUS
#    vus_col[j] <- tryCatch(
#      {
#        vus <- Normal.VUS(x,y,z,p=0,q=0,alpha=0.05)
#        vus_col[j] <- vus$estimate
#      },
#      error=function(cond){
#        message(paste(cond, "\n", sep=""))
#        return(NA)
#      }
#    )
#    
#    ###Calculate specificity
#    Se_col[j] <- tryCatch(
#      {
#        Se_col[j] <- Sp.Sm.Se(x,y,z,0.426,0.638)[3]
#        
#        ###Use affinity value###
#        #Se_col[j] <- Sp.Sm.Se(x,y,z,0.005,0.020)[3]
#      },
#      error=function(cond){
#        message(paste(cond, "\n", sep=""))
#        return(NA)
#      }
#    )
#    
#    vus_col[j] <- format(vus_col[j], digits=4)
#    Se_col[j] <- format(Se_col[j], digits=4)
#  }
#  df$vus <- vus_col
#  df$Se <- Se_col
#  write.table(as.matrix(df), outputfile, col.names=c("Allele", "VUS", "Se"), 
#              row.names=F, append=F, sep="\t")
#}
