ods html close;
options nodate nonumber;
ods pdf file='H:Group10_Project_Outputs.pdf' pdftoc=2;


/*RFM Segmentation*/
data a1;
infile 'H:\laundet_groc_1114_1165' dlm=' ' firstobs =2;
input IRI_KEY WEEK SY GE VEND ITEM UNITS DOLLAR F $ D PR;RUN;
proc import datafile = 'H:\prod_laundet.csv'
DBMS=CSV
OUT=A2;
GETNAMES=YES;RUN;
data a3;
infile 'H:\laundet_PANEL_GR_1114_1165.dat' firstobs = 2 expandtabs;
input panid week units_panel outlet $ dollars_panel iri_key colupc_1 ;
colupc = put(colupc_1,$14.);
drop colupc_1;
run;
proc print data=a3(obs=10);run;
proc import datafile = 'H:\ads demo3.csv'
DBMS=CSV
OUT=A4;
GETNAMES=YES;RUN;
PROC PRINT DATA = A4(OBS=10);
RUN;
PROC SQL;
CREATE TABLE S1 AS 
SELECT A1.*, A3.* FROM A1  JOIN A3 ON A1.IRI_KEY=A3.IRI_KEY;
QUIT;
proc print data=S1(obs=10);run;
PROC SQL;
CREATE TABLE S2 AS 
SELECT A1.*, A2.* FROM A1 JOIN A2 ON A1.SY=A2.SY AND A1.GE=A2.GE AND A1.VEND = A2.VEND AND A1.ITEM=A2.ITEM;
QUIT;
PROC PRINT DATA = S2(OBS=10);
RUN;
PROC SQL;
CREATE TABLE S3 AS 
SELECT A3.*, S2.* FROM A3 JOIN S2 ON A3.IRI_KEY=S2.IRI_KEY AND A3.WEEK=S2.WEEK;
QUIT;
PROC PRINT DATA = S3(OBS=10);
RUN;
PROC SQL;
CREATE TABLE S4 AS 
SELECT A4.*, S3.* FROM A4 JOIN S3 ON A4.panelist_id=S3.panid;
QUIT;
PROC PRINT DATA = S4(OBS=10);
RUN;

PROC MEANS DATA = S4;CLASS L5;RUN;

PROC SQL;
CREATE TABLE Rfm_Final AS
SELECT panid, SUM(DOLLAR) AS MONETARY,COUNT(week) AS FREQUENCY,MAX(week) AS LAST_PURCHASE,
MIN(1165-week) AS RECENCY
FROM S4
where L5 LIKE '%ISK%'
GROUP BY panid
HAVING FREQUENCY>1;
QUIT;
PROC PRINT DATA=Rfm_Final;run;

PROC CORR DATA=Rfm_Final;
VAR MONETARY FREQUENCY RECENCY;
RUN;

PROC MEANS DATA=Rfm_Final MIN P20 P40 P60 P80 MAX;
VAR MONETARY FREQUENCY RECENCY;
OUTPUT OUT=Cust_Percentile MIN= P20= P40= P60= P80= MAX=/ AUTONAME;
RUN;

/*CREATING CUSTOMER SEGMENTS*/
DATA RFM_Project;
SET RFM_Final;
FORMAT LAST_PURCHASE DDMMYY10.;
FORMAT LAST_WEEK DDMMYY10.;
ID=1;run;

DATA Cust_seg;
SET Cust_seg;
ID = 1;
RUN;

PROC SQL;
CREATE TABLE segment AS
SELECT * FROM
(SELECT * FROM RFM_Project) AS A
LEFT JOIN
(SELECT * FROM Cust_seg) AS B
ON A.ID=B.ID;
QUIT;

PROC print data=segment(obs=10);run;
/* Creating Segments */

DATA segment_2 (KEEP=Panelist_ID MONETARY FREQUENCY RECENCY SEGMENT );
SET segment;
IF (MONETARY > MONETARY_P80 & FREQUENCY > FREQUENCY_P80 & RECENCY < RECENCY_P20) THEN SEGMENT=1;
ELSE IF (FREQUENCY > FREQUENCY_P80) THEN SEGMENT=2;
ELSE IF (MONETARY > MONETARY_P80) THEN SEGMENT =3;
ELSE IF (FREQUENCY > FREQUENCY_P80 & MONETARY < MONETARY_P20|MONETARY < MONETARY_P40) THEN SEGMENT =4;
ELSE SEGMENT=0;
RUN;

PROC FREQ DATA=segment_2;
    TABLES SEGMENT;
RUN;
PROC PRINT DATA=segment_2(obs=10);run;
PROC SQL;
CREATE TABLE SEGMENT0 AS
SELECT * FROM segment_2 WHERE SEGMENT=0;
QUIT;
PROC PRINT DATA=SEGMENT0(OBS=10);RUN;

PROC SQL;
CREATE TABLE SEGMENT1 AS
SELECT * FROM Segment_2 WHERE SEGMENT=1;
QUIT;
PROC PRINT DATA=SEGMENT1(OBS=10);RUN;

PROC SQL;
CREATE TABLE SEGMENT2 AS
SELECT * FROM segment_2 WHERE SEGMENT=2;
QUIT;

PROC SQL;
CREATE TABLE SEGMENT3 AS
SELECT * FROM segment_2 WHERE SEGMENT=3;
QUIT;

PROC SQL;
CREATE TABLE SEGMENT4 AS
SELECT * FROM segment_2 WHERE SEGMENT=4;
QUIT;

PROC IMPORT DATAFILE='H:ads demo3.csv'
OUT=DEMOGRAPHICS
DBMS=CSV
REPLACE;
GETNAMES=YES;
DELIMITER=",";
RUN;

PROC PRINT DATA = demo(OBS=20);RUN;

DATA demo(KEEP = PANID INCOME FAM_SIZE RESIDENT_TYPE AGE_MALE_HH EDUC_MALE_HH OCC_MALE_HH MALE_WORK_HR AGE_FEMALE_HH EDUC_FEMALE_HH
OCC_FEMALE_HH FEMALE_WORK_HR NUM_DOGS NUM_CATS CHILD_AGEGP MARITAL_STATUS);
SET demo(RENAME = (Panelist_ID = PANID Combined_Pre_Tax_Income_of_HH = INCOME Family_Size = FAM_SIZE
Type_of_Residential_Possession = RESIDENT_TYPE Age_Group_Applied_to_Male_HH = AGE_MALE_HH Education_Level_Reached_by_Male = EDUC_MALE_HH
Occupation_Code_of_Male_HH = OCC_MALE_HH Male_Working_Hour_Code = MALE_WORK_HR Age_Group_Applied_to_Female_HH = AGE_FEMALE_HH
Education_Level_Reached_by_Femal = EDUC_FEMALE_HH Occupation_Code_of_Female_HH = OCC_FEMALE_HH Female_Working_Hour_Code = FEMALE_WORK_HR
Number_of_Dogs = NUM_DOGS Number_of_Cats = NUM_CATS Children_Group_Code = CHILD_AGEGP Marital_Status = MARITAL_STATUS));
RUN;

PROC PRINT DATA = demo(OBS=20);RUN;


PROC FREQ DATA=demo;
TABLE AGE_MALE_HH;
RUN;

PROC CONTENTS DATA = demo;RUN;

PROC SQL;
CREATE TABLE demo_1 AS
SELECT * FROM demo WHERE FAM_SIZE <> 0 AND RESIDENT_TYPE <> 0 AND AGE_MALE_HH <> 7 AND AGE_MALE_HH <> 0 AND EDUC_MALE_HH <> 9 AND EDUC_MALE_HH <> 0 AND OCC_MALE_HH <> 11 AND MALE_WORK_HR <> 7 AND
AGE_FEMALE_HH <> 7 AND AGE_FEMALE_HH <> 0 AND EDUC_FEMALE_HH <> 9 AND EDUC_FEMALE_HH <> 0 AND OCC_FEMALE_HH <> 11 AND FEMALE_WORK_HR <> 7 AND MARITAL_STATUS <> 0 AND CHILD_AGEGP <> 0 ;
QUIT;

PROC PRINT DATA = demo_1(OBS=20);RUN;

PROC SQL;
CREATE TABLE DEMO_CUST AS
SELECT
B.PANID,
CASE
WHEN B.FAM_SIZE IN (4,5,6) THEN 'LARGE'
ELSE 'REGULAR' END AS FAM_SIZE,

CASE
WHEN B.INCOME IN (1,2,3,4) THEN 'LOW'
WHEN B.INCOME IN (5,6,7,8) THEN 'MEDIUM'
WHEN B.INCOME IN (9,10,11,12) THEN 'HIGH'
ELSE 'VERY_HIGH' END AS FAM_INCOME,

CASE
WHEN B.AGE_MALE_HH IN (1) THEN 'YOUNG'
WHEN B.AGE_MALE_HH IN (2,3,4) THEN 'MID_AGE'
ELSE 'ELDER' END AS AGE_MALE,

CASE
WHEN B.AGE_FEMALE_HH IN (1) THEN 'YOUNG'
WHEN B.AGE_FEMALE_HH IN (2,3,4) THEN 'MID_AGE'
ELSE 'ELDER' END AS AGE_FEMALE,

CASE
WHEN B.EDUC_MALE_HH IN (1,2,3) THEN 'SCHOOL'
WHEN B.EDUC_MALE_HH IN (4,5,6) THEN 'COLLEGE'
ELSE 'GRADUATE' END AS EDUC_MALE,

CASE
WHEN B.EDUC_FEMALE_HH IN (1,2,3) THEN 'SCHOOL'
WHEN B.EDUC_FEMALE_HH IN (4,5,6) THEN 'COLLEGE'
ELSE 'GRADUATE' END AS EDUC_FEMALE,

CASE
WHEN B.CHILD_AGEGP IN (1,2,3) THEN 'ONE'
WHEN B.CHILD_AGEGP IN (4,5,6) THEN 'TWO'
WHEN B.CHILD_AGEGP IN (7) THEN 'THREE'
ELSE 'ZERO' END AS CHILD_NUM,

CASE
WHEN B.OCC_MALE_HH IN (1,2,3) THEN 'WHITE_HIGH'
WHEN B.OCC_MALE_HH IN (4,5) THEN 'WHITE_LOW'
WHEN B.OCC_MALE_HH IN (6,7,8,9) THEN 'BLUE'
WHEN B.OCC_MALE_HH IN (10,13) THEN 'NO_OCCUP'
ELSE 'OTHER' END AS OCCU_MALE,

CASE
WHEN B.OCC_FEMALE_HH IN (1,2,3) THEN 'WHITE_HIGH'
WHEN B.OCC_FEMALE_HH IN (4,5) THEN 'WHITE_LOW'
WHEN B.OCC_FEMALE_HH IN (6,7,8,9) THEN 'BLUE'
WHEN B.OCC_FEMALE_HH IN (10,13) THEN 'NO_OCCUP'
ELSE 'OTHER' END AS OCCU_FEMALE,

NUM_CATS + NUM_DOGS AS PETS_TOTAL

FROM demo_1 B
ORDER BY B.PANID;
QUIT;

PROC PRINT DATA = DEMO_CUST(OBS=5);RUN;

DATA DEMO_CUST;
SET DEMO_CUST;
IF FAM_SIZE='LARGE' THEN FAM_SIZE_L=1 ; ELSE FAM_SIZE_L=0;
IF FAM_SIZE='REGULAR' THEN FAM_SIZE_R=1 ; ELSE FAM_SIZE_R=0;

IF FAM_INCOME="LOW" THEN FAM_INCOME_L=1 ; ELSE FAM_INCOME_L=0;
IF FAM_INCOME="MEDIUM" THEN FAM_INCOME_M=1 ; ELSE FAM_INCOME_M=0;
IF FAM_INCOME="HIGH" THEN FAM_INCOME_H=1 ; ELSE FAM_INCOME_H=0;
IF FAM_INCOME="VERY_HIGH" THEN FAM_INCOME_VH=1 ; ELSE FAM_INCOME_VH=0;

IF AGE_MALE="YOUNG" THEN AGE_MY=1 ; ELSE AGE_MY=0;
IF AGE_MALE="MID_AGE" THEN AGE_MM=1 ; ELSE AGE_MM=0;
IF AGE_MALE="ELDER" THEN AGE_ME=1 ; ELSE AGE_ME=0;

IF AGE_FEMALE="YOUNG" THEN AGE_FY=1 ; ELSE AGE_FY=0;
IF AGE_FEMALE="MID_AGE" THEN AGE_FM=1 ; ELSE AGE_FM=0;
IF AGE_FEMALE="ELDER" THEN AGE_FE=1 ; ELSE AGE_FE=0;

IF EDUC_MALE="SCHOOL" THEN EDUC_MS=1 ; ELSE EDUC_MS=0;
IF EDUC_MALE="COLLEGE" THEN EDUC_MC=1 ; ELSE EDUC_MC=0;
IF EDUC_MALE="GRADUATE" THEN EDUC_MG=1 ; ELSE EDUC_MG=0;

IF EDUC_FEMALE="SCHOOL" THEN EDUC_FS=1 ; ELSE EDUC_FS=0;
IF EDUC_FEMALE="COLLEGE" THEN EDUC_FC=1 ; ELSE EDUC_FC=0;
IF EDUC_FEMALE="GRADUATE" THEN EDUC_FG=1 ; ELSE EDUC_FG=0;

IF OCCU_MALE="WHITE_HIGH" THEN OCC_MWH=1; ELSE OCC_MWH=0;
IF OCCU_MALE="WHITE_LOW" THEN OCC_MWL=1; ELSE OCC_MWL=0;
IF OCCU_MALE="BLUE" THEN OCC_MB=1; ELSE OCC_MB=0;
IF OCCU_MALE="NO_OCCUP" THEN OCC_MNO=1; ELSE OCC_MNO=0;
IF OCCU_MALE="OTHER" THEN OCC_MO=1; ELSE OCC_MO=0;

IF OCCU_FEMALE="WHITE_HIGH" THEN OCC_FWH=1; ELSE OCC_FWH=0;
IF OCCU_FEMALE="WHITE_LOW" THEN OCC_FWL=1; ELSE OCC_FWL=0;
IF OCCU_FEMALE="BLUE" THEN OCC_FB=1; ELSE OCC_FB=0;
IF OCCU_FEMALE="NO_OCCUP" THEN OCC_FNO=1; ELSE OCC_FNO=0;
IF OCCU_FEMALE="OTHER" THEN OCC_FO=1; ELSE OCC_FO=0;

IF CHILD_NUM='ONE' THEN CHILD_1=1; ELSE CHILD_1=0;
IF CHILD_NUM='TWO' THEN CHILD_2=1; ELSE CHILD_2=0;
IF CHILD_NUM='THREE' THEN CHILD_3=1; ELSE CHILD_3=0;
IF CHILD_NUM='ZERO' THEN CHILD_0=1; ELSE CHILD_0=0;

IF PETS_TOTAL=0 THEN PETS_0=1; ELSE PETS_0=0;
IF PETS_TOTAL NE 0 THEN PETS_GR_1=1; ELSE PETS_GR_1=0;

RUN;

PROC PRINT DATA = DEMO_CUST(OBS=5);RUN;

DATA DEMO_CUST (DROP = FAM_SIZE FAM_INCOME AGE_MALE AGE_FEMALE EDUC_MALE EDUC_FEMALE CHILD_NUM OCCU_MALE OCCU_FEMALE PETS_TOTAL);
SET DEMO_CUST;
RUN;

PROC PRINT DATA = DEMO_CUST(OBS=10);RUN;

/*segment 0*/
PROC SQL;
CREATE TABLE SEGMENT0_DEMO AS
SELECT * FROM
(SELECT * FROM SEGMENT0) AS A
INNER JOIN
(SELECT * FROM DEMO_CUST) AS B
ON A.Panelist_ID=B.PANID;
QUIT;

PROC PRINT DATA = SEGMENT0_DEMO(OBS=20);RUN;

DATA SEGMENT0_DEMO(DROP = MONETARY_Min RECENCY_Min MONETARY_P20 RECENCY_P20 MONETARY_P40 RECENCY_P40 MONETARY_P60 RECENCY_P60 MONETARY_P80 RECENCY_P80 MONETARY_Max
RECENCY_Max CLUSTER);
SET SEGMENT0_DEMO;
RUN;

PROC MEANS DATA=SEGMENT0_DEMO;RUN;
/*segment 1*/
PROC SQL;
CREATE TABLE SEGMENT1_DEMO AS
SELECT * FROM
(SELECT * FROM SEGMENT1) AS A
INNER JOIN
(SELECT * FROM DEMO_CUST) AS B
ON A.Panelist_ID=B.PANID;
QUIT;

PROC PRINT DATA = SEGMENT1_DEMO(OBS=20);RUN;

PROC MEANS DATA=SEGMENT1_DEMO;RUN;
DATA SEGMENT1_DEMO(DROP = MONETARY_Min RECENCY_Min MONETARY_P20 RECENCY_P20 MONETARY_P40 RECENCY_P40 MONETARY_P60 RECENCY_P60 MONETARY_P80 RECENCY_P80 MONETARY_Max
RECENCY_Max CLUSTER);
SET SEGMENT1_DEMO;
RUN;

PROC MEANS DATA=SEGMENT1_DEMO;RUN;
/*segment 2*/
PROC SQL;
CREATE TABLE SEGMENT2_DEMO AS
SELECT * FROM
(SELECT * FROM SEGMENT2) AS A
INNER JOIN
(SELECT * FROM DEMO_CUST) AS B
ON A.Panelist_ID=B.PANID;
QUIT;

PROC PRINT DATA = SEGMENT2_DEMO(OBS=20);RUN;

DATA SEGMENT2_DEMO(DROP = MONETARY_Min RECENCY_Min MONETARY_P20 RECENCY_P20 MONETARY_P40 RECENCY_P40 MONETARY_P60 RECENCY_P60 MONETARY_P80 RECENCY_P80 MONETARY_Max
RECENCY_Max CLUSTER);
SET SEGMENT2_DEMO;
RUN;

PROC MEANS DATA=SEGMENT2_DEMO;RUN;
/*segment 3*/
PROC SQL;
CREATE TABLE SEGMENT3_DEMO AS
SELECT * FROM
(SELECT * FROM SEGMENT3) AS A
INNER JOIN
(SELECT * FROM DEMO_CUST) AS B
ON A.Panelist_ID=B.PANID;
QUIT;

PROC PRINT DATA = SEGMENT3_DEMO(OBS=20);RUN;

DATA SEGMENT3_DEMO(DROP = MONETARY_Min RECENCY_Min MONETARY_P20 RECENCY_P20 MONETARY_P40 RECENCY_P40 MONETARY_P60 RECENCY_P60 MONETARY_P80 RECENCY_P80 MONETARY_Max
RECENCY_Max CLUSTER);
SET SEGMENT3_DEMO;
RUN;

PROC MEANS DATA=SEGMENT3_DEMO;RUN;
/* segment 4 */
PROC SQL;
CREATE TABLE SEGMENT4_DEMO AS
SELECT * FROM
(SELECT * FROM SEGMENT4) AS A
INNER JOIN
(SELECT * FROM DEMO_CUST) AS B
ON A.Panelist_ID=B.PANID;
QUIT;

PROC PRINT DATA = SEGMENT4_DEMO(OBS=20);RUN;

DATA SEGMENT4_DEMO(DROP = MONETARY_Min RECENCY_Min MONETARY_P20 RECENCY_P20 MONETARY_P40 RECENCY_P40 MONETARY_P60 RECENCY_P60 MONETARY_P80 RECENCY_P80 MONETARY_Max
RECENCY_Max CLUSTER);
SET SEGMENT4_DEMO;
RUN;

PROC MEANS DATA=SEGMENT4_DEMO;RUN;


/*logit */
/**/
/*Import ads demo3.csv__172684_1_1587165210000.csv AS A8
  Import prod_laundet.xls AS A2*/

/*laundet_groc_1114_1165*/
DATA a1; 
INFILE 'H:\laundet_groc_1114_1165' FIRSTOBS = 2;
INPUT IRI_KEY 2-7 WEEK 9-12 SY 14-15 GE 17-18 VEND 20-24 ITEM 26-30 UNITS 35-36 DOLLARS 38-45 
F $ 47-50 D 52-52 PR 54-54;run;

/*Import prod_laundet.xls AS A2*/
PROC PRINT data = A2(obs=10);run;

/*Reading Delivery stores*/
DATA A3; 
INFILE 'H:\Delivery_Stores' FIRSTOBS = 2;
INPUT IRI_KEY 2-7  OU $ 9-10 EST_ACV 12-19 Market_Name $ 21-44 Open 46-49 Clsd 51-54 MskdName $ 56-63;
proc print data = A3(obs=10);run;

/*Subsetting Wisk*/
Data SUBSET_WISK;set A2;If L5 ='WISK';run;
proc print data = SUBSET_WISK;run;

/*Creating UPC codes in one file so we can join the two data files using SQL*/
/*Adding leading new zeros*/
data A4;
        set A1;
        newSY= put(SY, z2.);
		newGE= put(GE, z2.);
		newVEND= put(VEND, z5.);
		newITEM= put(ITEM, z5.);
        run;
PROC PRINT data = A4(obs=10); run;

/*Concatenating the new UPC column*/
proc sql;
 create table OUT as select *,  cats(newSY,'-',newGE,'-',newVEND,'-',newITEM) as UPC from A4;
quit;
PROC PRINT data = OUT(obs=10); run;

/*Joining the two datasets */
PROC SQL;

CREATE TABLE A5 AS
SELECT *
FROM OUT A inner JOIN
SUBSET_WISK B
ON A.UPC = B.UPC
ORDER BY A.DOLLARS desc;
QUIT;

Proc print data = A5(obs=10);run;

/*Joining the already joined datasets with the new delivery data file */
PROC SQL;

CREATE TABLE A6 AS
SELECT *
FROM A5 A inner JOIN
A3 B
ON A.IRI_KEY = B.IRI_KEY
ORDER BY A.DOLLARS desc;
QUIT;

Proc print data = A6(obs=10);run;

/*Read laundet_PANEL_GR_1114_1165.dat data*/
DATA A7; 
INFILE 'H:\laundet_PANEL_GR_1114_1165.dat' FIRSTOBS = 2 ;
INPUT PANID 1-7 WEEK 9-12 UNITS 14-14 OUTLET $16 -17 DOLLARS 19-22	IRI_KEY	24-29 COLUPC 31-41;
proc print data = A7(obs=10);run;

PROC SQL;

CREATE TABLE PANELGROC AS
SELECT A.IRI_KEY,A.WEEK,A.UNITS,A.DOLLARS,A.F,A.D,A.PR,A.UPC,A.L2,A.L5,A.LEVEL,A.VOL_EQ,A.PACKAGE,A.FLAVOR_SCENT,A.CONCENTRATION_LEVEL,A.ADDITIVES,A.TYPE_OF_FORMULA,
A.EST_ACV,A.Market_Name,A.Open,A.Clsd,A.MskdName,
B.PANID ,B.WEEK,B.UNITS,B.DOLLARS,B.IRI_KEY,B.COLUPC
FROM A6 AS A inner JOIN
A7 AS B
ON A.IRI_KEY = B.IRI_KEY;
QUIT;

Proc print data = PANELGROC(OBS=10);run;

/Import ads demo 3 data/
proc print data = A8(obs=10);run;

/*Final data file*/
PROC SQL;

CREATE TABLE Project AS
SELECT A.IRI_KEY, A.WEEK ,A.UNITS, A.DOLLARS, A.F, A.D, A.PR, A.UPC, A.L2, A.L5, A.Level, A.VOL_EQ, A.PACKAGE, A.FLAVOR_SCENT, A.CONCENTRATION_LEVEL, A.ADDITIVES, 
A.TYPE_OF_FORMULA, A.EST_ACV, A.Market_Name, A.Open, A.Clsd, A.MskdName, A.PANID, A.COLUPC,B.Panelist_ID,B.Family_Size, B.Combined_Pre_Tax_Income_of_HH, B.ZIPCODE,B.Type_of_Residential_Possession,
B.HH_AGE,B.HH_EDU,B.HH_OCC,B.Number_of_Cats as Cats,B.Children_Group_Code as Children,B.Marital_Status 
FROM PANELGROC AS A inner JOIN
A8 AS B
ON A.PANID = B.Panelist_ID;
QUIT;

Proc print data = Project(OBS=10);run;

/*Proc Logistics on Panel data*/

PROC SQL;
CREATE TABLE Project_Logit AS
SELECT PANID, SUM(DOLLARS) AS Tot_Amount,COUNT(WEEK) AS Frequency,MAX(WEEK) AS Last_Visit, L5 as Detergent_Brand,
MIN(1165-WEEK) AS Recency,iri_key, avg(Combined_Pre_Tax_Income_of_HH) as pretax, avg(Family_Size) as FS, avg(Type_of_Residential_Possession) as TRP ,
 Zipcode,HH_AGE,HH_EDU,HH_OCC, Cats,Children,Marital_Status 
FROM Project
GROUP BY PANID
HAVING Frequency>1;
QUIT;

proc univariate data = Project_Logit; var Tot_Amount ;run;

proc univariate data = Project_Logit; var Frequency ;run; 

data Project_final;
set Project_Logit;
if Tot_Amount > 251795 & Frequency > 4374 then Repeating_Customer = 1;
else Repeating_Customer =0;run;
title1 'Repeating_Customer';run;

/*Proc Logistics without stepwise regression*/
proc logistic data=Project_final descending outmodel=betas1 desc;
	model Repeating_Customer = pretax FS TRP Zipcode HH_AGE HH_EDU HH_OCC Cats Children Marital_Status;
    output out=Project_predicted2;
run;
/*Proc Logistics with stepwise regression*/
proc logistic data=Project_final descending outmodel=betas1 desc;
	class pretax FS TRP Zipcode HH_AGE HH_EDU HH_OCC Cats Children Marital_Status / param=ref;
	model Repeating_Customer = pretax FS TRP Zipcode HH_AGE HH_EDU HH_OCC Cats Children Marital_Status/ selection=stepwise slentry= 0.3 slstay=0.2 expb;
    output out=Project_predicted predprobs=individual;
run;


/*Confusion Matrix*/
data confusion;
set Project_predicted;
if (IP_Yes >=0.50)then Repeating_Customer_hat='Yes'; else Repeating_Customer_hat='No';
run;

proc freq data=confusion;
table Repeating_Customer*Repeating_Customer_hat / nocum nocol nopercent norow;
run;
ods pdf close;

