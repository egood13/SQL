
/***** 
Update IT System account allocations. Pull updates from text file and combines
with data in our obi_gpr_allocation table.

NOTE: You can specify which months will be updated and which months will be
left alone by setting @month equal to the first month to make updates.

Created by: Elliott Good 
Last Edited: 11/28/16
*****/


-- Set variables to determine year/account/type that will be updated

DECLARE @year smallint
DECLARE @month smallint -- month at which updates can be inserted
DECLARE @account varchar(10)
DECLARE @act_pln bit

SET @year = 2017
SET @month = 1
SET @account = 'OVH272'
SET @act_pln = '1'


-- Insert updates into temp table


IF OBJECT_ID('tempdb..#_ALLOC') IS NOT NULL
	DROP TABLE #_ALLOC
	

CREATE TABLE #_ALLOC (
	 year    smallint	 NOT NULL
	,center  varchar(10) NOT NULL
	,account varchar(10) NOT NULL
	,product varchar(20) NOT NULL
	,jan    float   NOT NULL
	,feb	float	NOT NULL
	,mar	float	not null
	,apr	float	not null
	,may	float	not null
	,jun	float	not null
	,jul	float	not null
	,aug	float	not null
	,sep	float	not null
	,oct	float	not null
	,nov	float	not null
	,dec	float	not null
	,act_pln bit	NOT NULL
)

BULK INSERT #_ALLOC
FROM 'F:\SQL\PUBLIC\PORTAL\GPR_NON_OP_ALLOCATIONS\ALLOCATIONS_RUN_FILES\uploads\obi_gpr_alloc.txt'
WITH (
	FIELDTERMINATOR = '\t'
  , ROWTERMINATOR   = '\n'
  , FIRSTROW = 2
)



-- Combine historical data with updates in a temp table to prep for insert 
-- NOTE: verify which months you are making updates


IF OBJECT_ID('tempdb..#_TEMP') IS NOT NULL
	DROP TABLE #_TEMP

SELECT * INTO #_TEMP
FROM (
SELECT year
	  ,center
	  ,account
	  ,product
	  ,jan
	  ,feb
	  ,mar
	  ,apr
	  ,may
	  ,jun
	  ,jul
	  ,aug
	  ,sep
	  ,oct
	  ,nov
	  ,dec
	  ,act_pln
FROM (												-- join existing data with new data
	SELECT old.year
		  ,old.center
		  ,old.account
		  ,old.product
		  ,CASE WHEN @month <= 1 THEN new.jan ELSE old.jan END as jan
		  ,CASE WHEN @month <= 2 THEN new.feb ELSE old.feb END as feb
		  ,CASE WHEN @month <= 3 THEN new.mar ELSE old.mar END as mar
		  ,CASE WHEN @month <= 4 THEN new.apr ELSE old.apr END as apr
		  ,CASE WHEN @month <= 5 THEN new.may ELSE old.may END as may
		  ,CASE WHEN @month <= 6 THEN new.jun ELSE old.jun END as jun
		  ,CASE WHEN @month <= 7 THEN new.jul ELSE old.jul END as jul
		  ,CASE WHEN @month <= 8 THEN new.aug ELSE old.aug END as aug
		  ,CASE WHEN @month <= 9 THEN new.sep ELSE old.sep END as sep
		  ,CASE WHEN @month <= 10 THEN new.oct ELSE old.oct END as oct
		  ,CASE WHEN @month <= 11 THEN new.nov ELSE old.nov END as nov
		  ,CASE WHEN @month <= 12 THEN new.dec ELSE old.dec END as dec
		  ,old.act_pln
	FROM [FDM].[dbo].[obi_gpr_allocations] [old]
	JOIN #_ALLOC new ON     old.year = new.year
					 AND  old.center = new.center
					 AND old.account = new.account
					 AND old.product = new.product
					 AND old.act_pln = new.act_pln
) x

UNION ALL

SELECT new.year
	  ,new.center
	  ,new.account
	  ,new.product
	  ,CASE WHEN @month <= 1 THEN new.jan ELSE 0 END
	  ,CASE WHEN @month <= 2 THEN new.feb ELSE 0 END
	  ,CASE WHEN @month <= 3 THEN new.mar ELSE 0 END
	  ,CASE WHEN @month <= 4 THEN new.apr ELSE 0 END
	  ,CASE WHEN @month <= 5 THEN new.may ELSE 0 END
	  ,CASE WHEN @month <= 6 THEN new.jun ELSE 0 END
	  ,CASE WHEN @month <= 7 THEN new.jul ELSE 0 END
	  ,CASE WHEN @month <= 8 THEN new.aug ELSE 0 END
	  ,CASE WHEN @month <= 9 THEN new.sep ELSE 0 END
	  ,CASE WHEN @month <= 10 THEN new.oct ELSE 0 END
	  ,CASE WHEN @month <= 11 THEN new.nov ELSE 0 END
	  ,CASE WHEN @month <= 12 THEN new.dec ELSE 0 END
	  ,new.act_pln
FROM #_ALLOC new									-- add new data that doesn't exist in old data
WHERE NOT EXISTS (SELECT NULL 
				  FROM [FDM].[dbo].[obi_gpr_allocations] old 
				  WHERE  old.year = new.year
				  and  old.center = new.center
				  and old.account = new.account
				  and old.product = new.product
				  and old.act_pln = new.act_pln)

UNION ALL

SELECT year
	  ,center
	  ,account
	  ,product
	  ,CASE WHEN @month <= 1 THEN 0 ELSE old.jan END
	  ,CASE WHEN @month <= 2 THEN 0 ELSE old.feb END
	  ,CASE WHEN @month <= 3 THEN 0 ELSE old.mar END
	  ,CASE WHEN @month <= 4 THEN 0 ELSE old.apr END
	  ,CASE WHEN @month <= 5 THEN 0 ELSE old.may END
	  ,CASE WHEN @month <= 6 THEN 0 ELSE old.jun END
	  ,CASE WHEN @month <= 7 THEN 0 ELSE old.jul END
	  ,CASE WHEN @month <= 8 THEN 0 ELSE old.aug END
	  ,CASE WHEN @month <= 9 THEN 0 ELSE old.sep END
	  ,CASE WHEN @month <= 10 THEN 0 ELSE old.oct END
	  ,CASE WHEN @month <= 11 THEN 0 ELSE old.nov END
	  ,CASE WHEN @month <= 12 THEN 0 ELSE old.dec END
	  ,act_pln
FROM [FDM].[dbo].[obi_gpr_allocations] old			-- keep old data that doesn't exist in new data
WHERE NOT EXISTS (SELECT NULL 
				  FROM #_ALLOC new
				  WHERE  old.year = new.year
				  and  old.center = new.center
				  and old.account = new.account
				  and old.product = new.product
				  and old.act_pln = new.act_pln)
AND account = @account
and year = @year
AND act_pln = @act_pln
) x

--select * from #_TEMP

-- remove lines that contain 0 total allocations
DELETE FROM #_TEMP 
WHERE ([jan] + [feb] + [mar] + [apr] + [may] + [jun] + [jul] + [aug] + [sep] + [oct] + [nov] + [dec]) = 0


-- Delete old data and insert updated data

DELETE FROM [FDM].[dbo].[obi_gpr_allocations]
WHERE  year = @year
AND account = @account
AND act_pln = @act_pln

INSERT INTO [FDM].[dbo].[obi_gpr_allocations]
SELECT *
FROM #_TEMP


DROP TABLE #_TEMP