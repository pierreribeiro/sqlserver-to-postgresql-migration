/****** Object:  StoredProcedure [dbo].[MaterialToTransition]    Script Date: 21/10/2025 16:05:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[MaterialToTransition] @MaterialUid VARCHAR(50), @TransitionUid VARCHAR(50) AS
	INSERT INTO material_transition (material_id, transition_id) VALUES (@MaterialUid, @TransitionUid)
GO
