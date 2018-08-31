:setvar Table "sys.objects"

SELECT 
	CASE 
		WHEN OBJECT_ID('$(Table)') > 0 THEN CAST(1 AS BIT)
		ELSE CAST(0 AS BIT)
	END [TableExists]