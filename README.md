# NWEA
Scripts for processing NWEA MAP test results

##Purpose of the Scripts
This folder contains several scripts written in R. These can be used to process data files downloaded from NWEA MAP into reports that show growth by class and grade level and include various metrics used by Lighthouse Academies. The resulting reports are intended to supplement the existing reports available through the MAP site. As summaries, they do not provide the student-level data that is most valuable for teachers in differentiating instruction. They do, however, help automate the production of reports that show summarized results for all ELA or math classes on a single page.

##List of Files
1. FormatClassAssignments.R (partially automates the initial preparation of class assignments file to prepare it for use in the other scripts)
2. Fbaseline.R (creates tables of fall baseline scores by class and grade)
3. FtoWgrowth.R (creates tables of fall to winter growth by class and grade)
4. FtoSgrowth.R (creates tables of fall to spring growth by class and grade)
5. StoSgrowth.R (creates tables of spring to spring growth by class and grade)
6. Q1FtoSgrowth.R (creates tables of fall to growth growth by class and grade, but includes only students with baseline scores in the lowest quartile on national norms)
7. Q1StoSgrowth.R (creates tables of spring to spring growth by class and grade, but includes only students with baseline scores in the lowest quartile on national norms)
8. 2015NWEANorms.csv (data file containing national norms--must be present in working directory)

##How to Use the Scripts

###Step 1: Obtain the Data Files to Input
Use the "Data Export Scheduler" under "MAP Reports" in the MAP site to obtain the NWEA Comprehensive Data File package. The processing scripts are designed to work with the new file format NWEA introduced in summer 2015. Data files downloaded prior to this are not compatible, and should be re-downloaded in the new format. Note that comprehensive data files are updated nightly, and will not include test results from the current day.

1. Select "Enable" and "One Time", then select the desired term. (If measuring growth across two terms, you will need to go through these steps twice, once for each term.)
2. Select "Comprehensive Data File" and check the box to include the Class Assignments file.
3. Select the 2015 Norms.
4. Select "By School," indicate the schools for which you wish to download data, and click "Submit"
5. Wait for the MAP system to process the request, and then download the files. Although it says it may take 24 hours, export requests are usually processed every hour on the hour.
6. If the school is using a nightly export for Compass Learning, re-enable this after completing your download. (Option would have been pre-selected, and you would receive a warning when changing it to download the CDF.)

###Step 2: Rename the Data Files
When downloaded from NWEA, the Comprehensive Data File package consists of a zipped folder containing csv files:

*  The file "AssessmentResults.csv" contains test scores from the selected term. 

*  "StudentsBySchool.csv" contains names, school, and demographic info for all students rostered during the selected term. 

*  "ClassAssignments.csv" contains classes and teacher names for all students rostered during the selected term.
A box in the data export scheduler must be checked to include this file; it is not included by default.

Different test terms (e.g. fall, winter, spring) must be downloaded separately. Different schools may also be downloaded separately, especially if the schools use separate NWEA accounts. The files, however, will always have the same names. If processing data for multiple schools and/or using the scripts that calculate growth across two terms, it is highly recommended to rename each input file prior to processing. The following naming convention is suggested:
school abbreviation + term abbreviation + two-digit year + original file name

For example, rename the fall 2014 score file for Bronx Lighthouse Charter School as BLCSF14AssessmentResults.csv
and the winter 2015 class assignments file for Pine Bluff Lighthouse Charter School as PBLCSW15ClassAssignments.csv.

The scripts output csv files that also have generic names and do not specify the name of the school or the year. These should also be renamed immediately after running the script. If output files are not renamed or moved, and the script is run again, they will be overwritten.

Once all files are clearly named, they should be placed in the working directory. The file "2015NWEANorms.csv" must also be in the working directory. Use getwd() to identify working directory, setwd() to set it and list.files() to view files.

###Step 3: Prepare the Class Assignments File
Although the AssessmentResults.csv and StudentsBySchool.csv files can be used in the default format in which they are downloaded, ClassAssignments.csv must be modified. The data in ClassAssignments.csv is based on a class roster imported at the beginning of the test term, as well as any updates made in the MAP system during the test term. Different schools may name and list classes differently.

ClassAssignments.csv lists all class assignments that have been imported. When a student is enrolled in multiple classes (e.g. homeroom, ELA, math, science, history, art, music), each class is listed in a separate row. The NWEA MAP tests are for the subjects of math and reading. When creating data tables by teacher, each student's math and reading (or ELA) teachers must first be identified, so as to create reports that list those teachers and not the teachers of other subjects.

The script FormatClassAssignments.R helps automate the process of selecting the relevant data from ClassAssignments.csv and reformatting it such that it contains only one row for each student ID, with the student's ELA teacher and math teacher listed in the columns. The script looks for the most common names used by LHA schools to refer to ELA and math classes. To be selected, the class name must BEGIN with the word "Homeroom", "ELA", "Reading," Math", or "Algebra" (case insensitive). The script selects all rows meeting these criteria, then removes other information (such as section numbers) from the class names and renames any "Reading" classes to "ELA" and any "Algebra" classes to "Math." It then identifies any rows for which no ELA or math teacher is listed, and replaces these "NA" values with the name of the homeroom teacher. (Some schools import only homerooms for self-contained classes in which the homeroom teacher teaches all subjects.) 

In most cases, these steps should result in an output file (called "ClassAssignmentsProcessed.csv.") containing a single row for each student ID in column 1, the name of the student's ELA Teacher in column 2, and the name of the student's math Teacher in column 3. The script, however, will not work properly if ELA or math class names do not match the above criteria, or if students are enrolled in more than one ELA class or more than one math class. In these cases, manual pre-processing of the file will be required.

###Step 4: Select and Run the Processing Script
Choose the script you wish to run and execute it, using the command source("scriptname.R"). It will prompt you to enter the names of the data files to process. Hint: if you run list.files() immediately before running the script, the filenames will appear in the console, making it easy to type or copy and paste them at the prompts.

Upon completion, the script will save the output file(s) in csv format in your working directory and print a message to this effect.

###Step 5: Format the Output Files for Presentation
The output files contain all the data points typically included in the reports that had been created for Lighthouse schools with Excel in prior years. Column headings are similar to those in these Excel reports, but abbreviated and formatted without spaces or special characters as required by R. The data can be copied and pasted as values into the appropriate Excel template. Excel should automatically format most values correctly (as percents, rounded numbers, etc.) and add color coding through the conditional formatting built into the template. Some adjustments may be needed, however. 

In particular, the calculations in the school summary row will need to be checked. These are not calculated by the R scripts, and rely on Excel formulas. If the grade levels included in the data differ from those in the template, the Excel formulas will likely require adjustment.
