## This script takes as input a ClassAssignments.csv file downloaded from NWEA. 
## It outputs a formatted file listing the ELA and math teacher of each student.
## If the student does not have a teacher listed for a class beginning with the term "ELA" or "Reading", the homeroom teacher is used. 
## If the student does not have a teacher listed for a class beginning with the term "Math" or "Algebra", the homeroom teacher is used.
## The input file must meet certain conditions in order for this to work. Please see the Readme.

## Load required R packages
library(dplyr)
library(reshape2)

## Read Class Assignments file from CDF package into R
classfilename <- readline(prompt="Enter name of class assignments file to process. Include the .csv extension: ")
classes <- read.csv(classfilename)

## Remove any rows in which the class name does not start with the word "Homeroom", "ELA", "Reading," Math", or "Algebra."
rowlist <- grep("^homeroom|^ela|^math|^reading|^algebra", classes$ClassName, ignore.case=TRUE)
classes <- classes[rowlist,]

## Remove all other characters from the class names, effectively changing them to subject names
## Also change "Reading" (if used) to "ELA" and "Algebra" (if used) to "Math"
classes$ClassName <- gsub("homeroom.*", "Homeroom", classes$ClassName, ignore.case=TRUE)
classes$ClassName <- gsub("ela.*", "ELA", classes$ClassName, ignore.case=TRUE)
classes$ClassName <- gsub("math.*", "Math", classes$ClassName, ignore.case=TRUE)
classes$ClassName <- gsub("reading.*", "ELA", classes$ClassName, ignore.case=TRUE)
classes$ClassName <- gsub("algebra.*", "Math", classes$ClassName, ignore.case=TRUE)

## Cast into wide format, replace missing ELA or math teacher names with homeroom teacher and delete homerooms
classeswide <- dcast(classes, StudentID~ClassName, value.var="TeacherName")
if(!"ELA" %in% colnames(classeswide)){classeswide$ELA<-NA}
classeswide$ELA[is.na(classeswide$ELA)] <- classeswide$Homeroom[is.na(classeswide$ELA)]
if(!"Math" %in% colnames(classeswide)){classeswide$Math<-NA}
classeswide$Math[is.na(classeswide$Math)] <- classeswide$Homeroom[is.na(classeswide$Math)]
classeswide <- select(classeswide, -Homeroom)
names(classeswide) <- c("StudentID","ELATeacher","MathTeacher")

## Save file and print messages
write.csv(classeswide, file="ClassAssignmentsProcessed.csv", row.names=FALSE)
print("Processed file has been saved in working directory as ClassAssignmentsProcessed.csv.")
print("It is recommended that you check the file contents before proceeding to the next script.")
print("The number of rows should exactly equal the number of students tested and each student should have a Math and ELA teacher listed.")
print("Move or rename the output file before running this script again, or else file will be overwritten.")
