/****** Object:  StoredProcedure [dbo].[TransitionToMaterial]    Script Date: 21/10/2025 16:05:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[TransitionToMaterial] @TransitionUid VARCHAR(50), @MaterialUid VARCHAR(50) AS
	INSERT INTO transition_material (material_id, transition_id) VALUES (@MaterialUid, @TransitionUid)
GO
