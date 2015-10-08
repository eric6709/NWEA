## NWEA MAP Calculation of Fall to Winter Growth Results by Class and Grade, Displayed with Lighthouse Academies Metrics

## Load required R packages
library(dplyr)

print("NWEA MAP Fall to Winter Growth by Class and Grade")
print("This program requires as input the WINTER term AssessmentResults.csv, StudentsBySchool.csv, and processed ClassAssignments.csv files from the NWEA Comprehensive Data File Package, AND the FALL term AssessmentResults.csv file.") 
print("It also requires that the file 2015NWEANorms.csv be in the working directory.")
print("The program outputs tables with growth data for each class and grade level.")
print("Please see the readme file for important information on file name and pre-processing requirements")

## Read Winter Assessment Results file from CDF package into R
wscoresfilename <- readline(prompt="Enter name of file containing the WINTER scores. Include the .csv extension: ")
wscores <- read.csv(wscoresfilename)

## Read Student Demographics file from CDF package into R
wstudentsfilename <- readline(prompt="Enter name of file containing the WINTER student names and grade levels. Include the .csv extension: ")
wstudents <- read.csv(wstudentsfilename)

## Read Class Assignments file from CDF package into R
wteachersfilename <- readline(prompt="Enter name of file containing the WINTER teacher names. Include the .csv extension: ")
wteachers <- read.csv(wteachersfilename)

## Read Fall Assessment Results file from CDF package into R
fscoresfilename <- readline(prompt="Enter name of file containing the FALL baseline scores. Include the .csv extension: ")
fscores <- read.csv(fscoresfilename)

## Read 2015 Norms into R
norms <- read.csv("2015NWEANorms.csv")

## Check if number of students in demographics file equals number in class assignments file and warn if it does not
if(nrow(wstudents)!=nrow(wteachers)){warning("Number of students listed in demographics file does not equal number in class assignments file. Some students may be associated with more than one ELA or math teacher, or to no teacher and excluded from reports.")}

## Change grade K to 0 in student demographics file so that it is placed before grade 1 in sort order
wstudents$Grade <- gsub("K","0",wstudents$Grade)

## Merge winter student info with winter teacher names
## To work properly, the Class Assignments file should contain exactly one row for each student, with one ELA teacher and one math teacher listed.
## Any students without teachers in the Class Assignments file will be included with teachers listed as "NA"
## But any students whose IDs are not in the Student Demographics file will be excluded (should not normally happen)
wteachers <- select(wteachers, StudentID, ELATeacher, MathTeacher)
wstudentswithteachers <- merge(x=wstudents, y=wteachers, by="StudentID", all.x=TRUE)

## Merge winter student info with winter scores, joining on student ID
## Include any records in the score table that are not in the student info table (should not usually happen)
## but do not include records in the student info table not in the score table (students not tested)
wscores <- select(wscores, -TermName, -SchoolName)
wdata <- merge(x=wstudentswithteachers, y=wscores, by="StudentID", all.y=TRUE)

## Remove from winter scores any test results that are not valid growth measures
## and any results for which there was no growth projection (usually due to lack of baseline score)
wdata <- wdata %>%
        filter(GrowthMeasureYN==TRUE) %>%
        filter(!is.na(FallToWinterProjectedGrowth))

## Remove from fall scores any test results that are not valid growth measures       
fscores <- filter(fscores, GrowthMeasureYN==TRUE)

## Select the variables needed and create separate, sorted tables for math and reading
wmdata <- wdata %>% select(StudentID, StudentLastName, StudentFirstName, Grade, MathTeacher, TermName, SchoolName, MeasurementScale, WinterRIT=TestRITScore, WinterSE=TestStandardError, WinterPercentile=TestPercentile, FallToWinterProjectedGrowth, FallToWinterObservedGrowth) %>%
        filter(MeasurementScale == "Mathematics") %>%
        arrange(Grade, MathTeacher, StudentLastName, StudentFirstName)

wrdata <- wdata %>% select(StudentID, StudentLastName, StudentFirstName, Grade, ELATeacher, TermName, SchoolName, MeasurementScale, WinterRIT=TestRITScore, WinterSE=TestStandardError, WinterPercentile=TestPercentile, FallToWinterProjectedGrowth, FallToWinterObservedGrowth) %>%
        filter(MeasurementScale == "Reading") %>%
        arrange(Grade, ELATeacher, StudentLastName, StudentFirstName)

fmscores <- fscores %>% select(StudentID, MeasurementScale, FallRIT=TestRITScore, FallSE=TestStandardError, FallPercentile=TestPercentile) %>%
        filter(MeasurementScale == "Mathematics")

frscores <- fscores %>% select(StudentID, MeasurementScale, FallRIT=TestRITScore, FallSE=TestStandardError, FallPercentile=TestPercentile) %>%
        filter(MeasurementScale == "Reading")

## Create new columns with quartile in winter data (derived from percentile)
wmdata <- mutate(wmdata, Quartile = ceiling((WinterPercentile/25)+.0001))
wrdata <- mutate(wrdata, Quartile = ceiling((WinterPercentile/25)+.0001))
wmdata <- mutate(wmdata, Q1=Quartile==1, Q2=Quartile==2, Q3=Quartile==3, Q4=Quartile==4)
wrdata <- mutate(wrdata, Q1=Quartile==1, Q2=Quartile==2, Q3=Quartile==3, Q4=Quartile==4)

## Merge fall scores into the winter data files, keeping only records for students who have both fall and winter scores
mgrowthscores <- merge(x=wmdata, y=fmscores, by="StudentID")
rgrowthscores <- merge(x=wrdata, y=frscores, by="StudentID")

## Create growth index columns
mgrowthscores <- mutate(mgrowthscores, GrowthIndex = FallToWinterObservedGrowth - FallToWinterProjectedGrowth)
mgrowthscores <- mutate(mgrowthscores, GrowthProjectionMet = GrowthIndex>=0)
rgrowthscores <- mutate(rgrowthscores, GrowthIndex = FallToWinterObservedGrowth - FallToWinterProjectedGrowth)
rgrowthscores <- mutate(rgrowthscores, GrowthProjectionMet = GrowthIndex>=0)

## Create growth error columns for calculating error bands
mgrowthscores <- mgrowthscores %>% mutate(GrowthSE = sqrt(FallSE*FallSE + WinterSE*WinterSE))
rgrowthscores <- rgrowthscores %>% mutate(GrowthSE = sqrt(FallSE*FallSE + WinterSE*WinterSE))

## Summarize the data by class, then add error bands and winter status norms
mgrowthbyclass <- mgrowthscores %>% 
        group_by(Grade, MathTeacher) %>%
        summarize(NumberInCohort = n(), 
                  FallMeanRIT = mean(FallRIT), 
                  WinterMeanRIT = mean(WinterRIT),
                  ActualMeanRITGrowth = mean(FallToWinterObservedGrowth), 
                  TypicalMeanRITGrowth = mean(FallToWinterProjectedGrowth),
                  PercentOfTypicalGrowthAchieved = mean(FallToWinterObservedGrowth) / mean(FallToWinterProjectedGrowth),
                  AvgGrowthSE = mean(GrowthSE),
                  NumberMeetingOrExceedingGrowthProjection = sum(GrowthProjectionMet), 
                  PercentMeetingOrExceedingGrowthProjection = sum(GrowthProjectionMet) / n(),
                  NumberinQuartile1 = sum(Q1), 
                  NumberinQuartile2 = sum(Q2), 
                  NumberinQuartile3 = sum(Q3), 
                  NumberinQuartile4 = sum(Q4)) %>%
        mutate(PercentInHighestQuartile = NumberinQuartile4 / NumberInCohort) %>%
        mutate(CohortGrowthME = (AvgGrowthSE/sqrt(NumberInCohort))*2) %>%
        mutate(PercentofTypicalGrowthLowerBound = (ActualMeanRITGrowth - CohortGrowthME) / TypicalMeanRITGrowth) %>%
        mutate(PercentofTypicalGrowthUpperBound = (ActualMeanRITGrowth + CohortGrowthME) / TypicalMeanRITGrowth)
wmnorms <- select(norms, Grade, NationalNormWinterMeanMathRIT) 
mgrowthbyclass <- merge(x=mgrowthbyclass, y=wmnorms)
mgrowthbyclass <- mgrowthbyclass %>%
        mutate(NationalNormWinterMeanExceededOrMissedBy = WinterMeanRIT - NationalNormWinterMeanMathRIT)
mgrowthbyclass <- mgrowthbyclass[,c(2,1,3,4,5,20,21,6,7,8,18,19,10,11,12,13,14,15,16)]

rgrowthbyclass <- rgrowthscores %>% 
        group_by(Grade, ELATeacher) %>%
        summarize(NumberInCohort = n(), 
                  FallMeanRIT = mean(FallRIT), 
                  WinterMeanRIT = mean(WinterRIT),
                  ActualMeanRITGrowth = mean(FallToWinterObservedGrowth), 
                  TypicalMeanRITGrowth = mean(FallToWinterProjectedGrowth),
                  PercentOfTypicalGrowthAchieved = mean(FallToWinterObservedGrowth) / mean(FallToWinterProjectedGrowth),
                  AvgGrowthSE = mean(GrowthSE),
                  NumberMeetingOrExceedingGrowthProjection = sum(GrowthProjectionMet), 
                  PercentMeetingOrExceedingGrowthProjection = sum(GrowthProjectionMet) / n(),
                  NumberinQuartile1 = sum(Q1), 
                  NumberinQuartile2 = sum(Q2), 
                  NumberinQuartile3 = sum(Q3), 
                  NumberinQuartile4 = sum(Q4)) %>%
        mutate(PercentInHighestQuartile = NumberinQuartile4 / NumberInCohort) %>%
        mutate(CohortGrowthME = (AvgGrowthSE/sqrt(NumberInCohort))*2) %>%
        mutate(PercentofTypicalGrowthLowerBound = (ActualMeanRITGrowth - CohortGrowthME) / TypicalMeanRITGrowth) %>%
        mutate(PercentofTypicalGrowthUpperBound = (ActualMeanRITGrowth + CohortGrowthME) / TypicalMeanRITGrowth)
wrnorms <- select(norms, Grade, NationalNormWinterMeanReadingRIT) 
rgrowthbyclass <- merge(x=rgrowthbyclass, y=wrnorms)
rgrowthbyclass <- rgrowthbyclass %>%
        mutate(NationalNormWinterMeanExceededOrMissedBy = WinterMeanRIT - NationalNormWinterMeanReadingRIT)
rgrowthbyclass <- rgrowthbyclass[,c(2,1,3,4,5,20,21,6,7,8,18,19,10,11,12,13,14,15,16)] 

## Summarize data by grade
mgrowthbygrade <- mgrowthscores %>% 
        group_by(Grade) %>%
        summarize(NumberInCohort = n(), 
                  FallMeanRIT = mean(FallRIT), 
                  WinterMeanRIT = mean(WinterRIT),
                  ActualMeanRITGrowth = mean(FallToWinterObservedGrowth), 
                  TypicalMeanRITGrowth = mean(FallToWinterProjectedGrowth),
                  PercentOfTypicalGrowthAchieved = mean(FallToWinterObservedGrowth) / mean(FallToWinterProjectedGrowth),
                  AvgGrowthSE = mean(GrowthSE),
                  NumberMeetingOrExceedingGrowthProjection = sum(GrowthProjectionMet), 
                  PercentMeetingOrExceedingGrowthProjection = sum(GrowthProjectionMet) / n(),
                  NumberinQuartile1 = sum(Q1), 
                  NumberinQuartile2 = sum(Q2), 
                  NumberinQuartile3 = sum(Q3), 
                  NumberinQuartile4 = sum(Q4)) %>%
        mutate(PercentInHighestQuartile = NumberinQuartile4 / NumberInCohort) %>%
        mutate(CohortGrowthME = (AvgGrowthSE/sqrt(NumberInCohort))*2) %>%
        mutate(PercentofTypicalGrowthLowerBound = (ActualMeanRITGrowth - CohortGrowthME) / TypicalMeanRITGrowth) %>%
        mutate(PercentofTypicalGrowthUpperBound = (ActualMeanRITGrowth + CohortGrowthME) / TypicalMeanRITGrowth)
wmnorms <- select(norms, Grade, NationalNormWinterMeanMathRIT) 
mgrowthbygrade <- merge(x=mgrowthbygrade, y=wmnorms)
mgrowthbygrade <- mgrowthbygrade %>%
        mutate(NationalNormWinterMeanExceededOrMissedBy = WinterMeanRIT - NationalNormWinterMeanMathRIT)
mgrowthbygrade <- mgrowthbygrade[,c(1,2,3,4,19,20,5,6,7,17,18,9,10,11,12,13,14,15)]

rgrowthbygrade <- rgrowthscores %>% 
        group_by(Grade) %>%
        summarize(NumberInCohort = n(), 
                  FallMeanRIT = mean(FallRIT), 
                  WinterMeanRIT = mean(WinterRIT),
                  ActualMeanRITGrowth = mean(FallToWinterObservedGrowth), 
                  TypicalMeanRITGrowth = mean(FallToWinterProjectedGrowth),
                  PercentOfTypicalGrowthAchieved = mean(FallToWinterObservedGrowth) / mean(FallToWinterProjectedGrowth),
                  AvgGrowthSE = mean(GrowthSE),
                  NumberMeetingOrExceedingGrowthProjection = sum(GrowthProjectionMet), 
                  PercentMeetingOrExceedingGrowthProjection = sum(GrowthProjectionMet) / n(),
                  NumberinQuartile1 = sum(Q1), 
                  NumberinQuartile2 = sum(Q2), 
                  NumberinQuartile3 = sum(Q3), 
                  NumberinQuartile4 = sum(Q4)) %>%
        mutate(PercentInHighestQuartile = NumberinQuartile4 / NumberInCohort) %>%
        mutate(CohortGrowthME = (AvgGrowthSE/sqrt(NumberInCohort))*2) %>%
        mutate(PercentofTypicalGrowthLowerBound = (ActualMeanRITGrowth - CohortGrowthME) / TypicalMeanRITGrowth) %>%
        mutate(PercentofTypicalGrowthUpperBound = (ActualMeanRITGrowth + CohortGrowthME) / TypicalMeanRITGrowth)
wrnorms <- select(norms, Grade, NationalNormWinterMeanReadingRIT) 
rgrowthbygrade <- merge(x=rgrowthbygrade, y=wrnorms)
rgrowthbygrade <- rgrowthbygrade %>%
        mutate(NationalNormWinterMeanExceededOrMissedBy = WinterMeanRIT - NationalNormWinterMeanReadingRIT)
rgrowthbygrade <- rgrowthbygrade[,c(1,2,3,4,19,20,5,6,7,17,18,9,10,11,12,13,14,15)] 

## Save tables to files and print completion message
write.csv(mgrowthbyclass, file="FallToWinterMathGrowthByClass.csv", row.names=FALSE)
write.csv(rgrowthbyclass, file="FallToWinterReadingScoresByClass.csv", row.names=FALSE)
write.csv(mgrowthbygrade, file="FallToWinterMathGrowthByGrade.csv", row.names=FALSE)
write.csv(rgrowthbygrade, file="FallToWinterReadingGrowthByGrade.csv", row.names=FALSE)
print("Processing complete!")
print("Output files have been saved in working directory.")
print("Move or rename output files before running this script again, or else files will be overwritten.")