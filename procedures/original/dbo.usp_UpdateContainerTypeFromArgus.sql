/****** Object:  StoredProcedure [dbo].[usp_UpdateContainerTypeFromArgus]    Script Date: 21/10/2025 16:05:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[usp_UpdateContainerTypeFromArgus]
AS
BEGIN
UPDATE perseus.dbo.container
SET container_type_id = 12
FROM perseus.dbo.container c
JOIN OPENQUERY(SCAN2, 'select * from scan2.argus.root_plate 
               WHERE plate_format_id = 8 AND hermes_experiment_id IS NOT NULL') rp 
			   ON rp.uid = c.uid AND c.container_type_id != 12;
END
GO
