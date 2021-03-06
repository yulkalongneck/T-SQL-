USE [db]
GO
/****** Object:  UserDefinedFunction [dbo].[utl_f_ConvertEpochToDateTime]    Script Date: 6/5/2018 10:48:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER FUNCTION [dbo].[utl_f_ConvertEpochToDateTime](@Epoch bigint)  
RETURNS datetime  
AS  
BEGIN  
	DECLARE @Date datetime;  
	 IF @Epoch IS NOT NULL
		BEGIN 
			SET @Date = DATEADD(ms, @Epoch%1000, DATEADD(SECOND, @Epoch / 1000, '1970-1-01 00:00:00'))
		END
	 ELSE
		BEGIN
			SET @Date = null;
		END
	 RETURN(@Date);
END;  
