## NWEA MAP Calculation of Fall Baseline Results by Class and Grade, Displayed with Lighthouse Academies Metrics

## Load required R packages
library(dplyr)

print("NWEA MAP Fall Baseline by Class and Grade")
print("This program requires as input the AssessmentResults.csv, StudentsBySchool.csv, and processed ClassAssignments.csv files from the NWEA Comprehensive Data File Package. These should all be for the FALL term.") 
print("It also requires that the file 2015NWEANorms.csv be in the working directory.")
print("The program outputs tables with baseline data for each class and grade level.")
print("Please see the readme file for important information on file name and pre-processing requirements")

## Read Assessment Results file from CDF package into R
fscoresfilename <- readline(prompt="Enter name of file containing the FALL scores. Include the .csv extension: ")
fscores <- read.csv(fscoresfilename)

## Read Student Demographics file from CDF package into R
fstudentsfilename <- readline(prompt="Enter name of file containing the FALL student names and grade levels. Include the .csv extension: ")
fstudents <- read.csv(fstudentsfilename)

## Read Class Assignments file from CDF package into R
fteachersfilename <- readline(prompt="Enter name of file containing the FALL teacher names. Include the .csv extension: ")
fteachers <- read.csv(fteachersfilename)

## Read 2015 Norms into R
norms <- read.csv("2015NWEANorms.csv")

## Check if number of students in demographics file equals number in class assignments file and warn if it does not
if(nrow(fstudents)!=nrow(fteachers)){warning("Number of students listed in demographics file does not equal number in class assignments file. Some students may be associated with more than one ELA or math teacher, or to no teacher and excluded from reports.")}

## Change grade K to 0 so that it is placed before grade 1 in sort order
fstudents$Grade <- gsub("K","0",fstudents$Grade)

## Merge student info with teacher names
## To work properly, the Class Assignments file should contain exactly one row for each student, with one ELA teacher and one math teacher listed.
## Any students without teachers in the Class Assignments file will be included with teachers listed as "NA"
## But any students whose IDs are not in the Student Demographics file will be excluded (should not normally happen)
fteachers <- select(fteachers, StudentID, ELATeacher, MathTeacher)
fstudentswithteachers <- merge(x=fstudents, y=fteachers, by="StudentID", all.x=TRUE)

## Merge student info with scores, joining on student ID
## Include any records in the score table that are not in the student info table (should not usually happen)
## but do not include records in the student info table not in the score table (students not tested)
fscores <- select(fscores, -TermName, -SchoolName)
fdata <- merge(x=fstudentswithteachers, y=fscores, by="StudentID", all.y=TRUE)

## Remove any test results that are not valid growth measures
fdata <- filter(fdata, GrowthMeasureYN==TRUE)

## Select the variables needed and create separate, sorted tables for math and reading
fmdata <- fdata %>% select(StudentID, StudentLastName, StudentFirstName, Grade, MathTeacher, TermName, SchoolName, MeasurementScale, TestRITScore, TestStandardError, TestPercentile) %>%
        filter(MeasurementScale == "Mathematics") %>%
        arrange(Grade, MathTeacher, StudentLastName, StudentFirstName)

frdata <- fdata %>% select(StudentID, StudentLastName, StudentFirstName, Grade, ELATeacher, TermName, SchoolName, MeasurementScale, TestRITScore, TestStandardError, TestPercentile) %>%
        filter(MeasurementScale == "Reading") %>%
        arrange(Grade, ELATeacher, StudentLastName, StudentFirstName)

##Create columns with quartile (derived from percentile)
fmdata <- mutate(fmdata, Quartile = ceiling((TestPercentile/25)+.0001))
frdata <- mutate(frdata, Quartile = ceiling((TestPercentile/25)+.0001))
fmdata <- mutate(fmdata, Q1=Quartile==1, Q2=Quartile==2, Q3=Quartile==3, Q4=Quartile==4)
frdata <- mutate(frdata, Q1=Quartile==1, Q2=Quartile==2, Q3=Quartile==3, Q4=Quartile==4)

## Summarize the data by class and add fall norms
fmbyclass <- fmdata %>% group_by(Grade, MathTeacher) %>%
        summarize(NumberTested = n(), AvgMathRIT = mean(TestRITScore), NumberinQuartile1 = sum(Q1), NumberinQuartile2 = sum(Q2), NumberinQuartile3 = sum(Q3), NumberinQuartile4 = sum(Q4))
fmnorms <- select(norms, Grade, NationalNormFallMeanMathRIT, TypicalFallToSpringMathGrowth)
fmbyclass <- merge(fmbyclass, fmnorms)
fmbyclass <- fmbyclass[,c(1,2,3,4,9,10,5,6,7,8)]
frbyclass <- frdata %>% group_by(Grade, ELATeacher) %>%
        summarize(NumberTested = n(), AvgReadRIT = mean(TestRITScore), NumberinQuartile1 = sum(Q1), NumberinQuartile2 = sum(Q2), NumberinQuartile3 = sum(Q3), NumberinQuartile4 = sum(Q4))
frnorms <- select(norms, Grade, NationalNormFallMeanReadingRIT, TypicalFallToSpringReadingGrowth)
frbyclass <- merge(frbyclass, frnorms)
frbyclass <- frbyclass[,c(1,2,3,4,9,10,5,6,7,8)]

## Summarize data by grade and add fall norms
fmbygrade <- fmdata %>% group_by(Grade) %>%
        summarize(NumberTested = n(), AvgMathRIT = mean(TestRITScore), NumberinQuartile1 = sum(Q1), NumberinQuartile2 = sum(Q2), NumberinQuartile3 = sum(Q3), NumberinQuartile4 = sum(Q4))
fmbygrade <- merge(fmbygrade, fmnorms)
fmbygrade <- fmbygrade[,c(1,2,3,8,9,4,5,6,7)]
frbygrade <- frdata %>% group_by(Grade) %>%
        summarize(NumberTested = n(), AvgReadRIT = mean(TestRITScore), NumberinQuartile1 = sum(Q1), NumberinQuartile2 = sum(Q2), NumberinQuartile3 = sum(Q3), NumberinQuartile4 = sum(Q4))
frbygrade <- merge(frbygrade, frnorms)
frbygrade <- frbygrade[,c(1,2,3,8,9,4,5,6,7)]

## Save tables to files and print completion message
write.csv(fmbyclass, file="FallMathScoresByClass.csv", row.names=FALSE)
write.csv(frbyclass, file="FallReadingScoresByClass.csv", row.names=FALSE)
write.csv(fmbygrade, file="FallMathScoresByGrade.csv", row.names=FALSE)
write.csv(frbygrade, file="FallReadingScoresByGrade.csv", row.names=FALSE)
print("Processing complete!")
print("Output files have been saved in working directory.")
print("Move or rename output files before running this script again, or else files will be overwritten.")