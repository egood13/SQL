/* 

This query inserts 'as reported' data into missing cnv data columns (columns 
after current month to end of year).

Pass "ACT" and 'prior year' or "PLN" and 'current year' as arguments.

Created on 3/10/16 by Elliott Good

EXEC FDM.dbo.grp_account_center_join_cnv_asr @year = '2015', @act_pln = 'ACT'
EXEC FDM.dbo.grp_account_center_join_cnv_asr @year = '2016', @act_pln = 'PLN'

*/

ALTER PROCEDURE [dbo].[gpr_account_center_join_cnv_asr_zzzz]
	 @year    smallint
	,@act_pln varchar(3)

AS
BEGIN

	-- set up temp table structure
	SELECT TOP 0 * 
	INTO #TEMP_CNV 
	FROM [FDM].[dbo].[gpr_center_account_cnv]

	-- insert combined data into temp table
	INSERT INTO #TEMP_CNV
	SELECT   cnv.year
			,cnv.center
			,cnv.location
			,cnv.location_description
			,cnv.area_1_description
			,cnv.area_2_description
			,cnv.area_3_description
			,cnv.area_4_description
			,cnv.area_5_description
			,cnv.account_description
			,cnv.product
			,jan = CASE WHEN DATEPART(mm,GETDATE()) >= 1 THEN cnv.jan ELSE asr.jan END
			,feb = CASE WHEN DATEPART(mm,GETDATE()) >= 2 THEN cnv.feb ELSE asr.feb END
			,mar = CASE WHEN DATEPART(mm,GETDATE()) >= 3 THEN cnv.mar ELSE asr.mar END
			,apr = CASE WHEN DATEPART(mm,GETDATE()) >= 4 THEN cnv.apr ELSE asr.apr END
			,may = CASE WHEN DATEPART(mm,GETDATE()) >= 5 THEN cnv.may ELSE asr.may END
			,jun = CASE WHEN DATEPART(mm,GETDATE()) >= 6 THEN cnv.jun ELSE asr.jun END
			,jul = CASE WHEN DATEPART(mm,GETDATE()) >= 7 THEN cnv.jul ELSE asr.jul END
			,aug = CASE WHEN DATEPART(mm,GETDATE()) >= 8 THEN cnv.aug ELSE asr.aug END
			,sep = CASE WHEN DATEPART(mm,GETDATE()) >= 9 THEN cnv.sep ELSE asr.sep END
			,oct = CASE WHEN DATEPART(mm,GETDATE()) >= 10 THEN cnv.oct ELSE asr.oct END
			,nov = CASE WHEN DATEPART(mm,GETDATE()) >= 11 THEN cnv.nov ELSE asr.nov END
			,dec = CASE WHEN DATEPART(mm,GETDATE()) >= 12 THEN cnv.dec ELSE asr.dec END
			,cnv.act_pln
	FROM [FDM].[dbo].[gpr_center_account_cnv] cnv JOIN [FDM].[dbo].[gpr_center_account] asr
		ON     cnv.year = asr.year
		AND  cnv.center = asr.center
		AND cnv.product = asr.product
		AND cnv.act_pln = asr.act_pln
		AND cnv.account_description = asr.account_description
	WHERE cnv.year = @year
	AND cnv.act_pln = @act_pln

	-- delete data from cnv table and replace with data from temp table
	DELETE FROM [FDM].[dbo].[gpr_center_account_cnv]
	WHERE act_pln = @act_pln
	AND      year = @year


	INSERT INTO [FDM].[dbo].[gpr_center_account_cnv]
	SELECT *
	FROM #TEMP_CNV


	DROP TABLE #TEMP_CNV

END






GO


