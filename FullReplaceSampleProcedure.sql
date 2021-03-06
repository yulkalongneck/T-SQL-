USE [db]
GO
/****** Object:  StoredProcedure [dbo].[UpdateResources]    Script Date: 6/5/2018 10:49:37 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER Procedure [dbo].[UpdateResources]
@GroupID nvarchar(50),
@CustomerID nvarchar(50),
@EventID nvarchar(50),
@GroupTitle nvarchar(max),
@GroupDescription nvarchar(max),
@SortOrder int,
@ResourcesInput ResourceTable readonly
as

	Declare @date datetime
	Set @date = GETDATE()

	
 -- create a new group if the @GroupID is null
	IF @GroupID IS NULL OR @GroupID = ''
		begin
		--delcare new Group @groupID
			Declare @InsertedGroupID table( GroupID nvarchar(50))
			
			-- insert a new group from the update collection
			INSERT INTO [dbo].[TableResourceGroups] (GroupID, EventID, CustomerID, GroupTitle, GroupDescription, SortOrder, DateCreated, DateModified)
			OUTPUT inserted.GroupID INTO @InsertedGroupID
			VALUES (LOWER(NewID()), @EventID, @CustomerID, @GroupTitle, @GroupDescription,@SortOrder, @date, @date )

			-- insert resources where ResourceID is null from @ResourcesInput
			INSERT INTO [dbo].[TableResources] (ResourceID, GroupID, EventID, ResourceType, ResourceTitle, ResourceURL, SortOrder, DateCreated, DateModified)
			SELECT LOWER(NewID()) as ResourceID, (SELECT TOP(1) GroupID FROM @InsertedGroupID), @EventID, rs.ResourceType, rs.Title, rs.ResourceURL,  rs.SortOrder, @date, @date
			FROM @ResourcesInput rs
			where rs.ResourceID IS NULL OR (Select ResourceID From TableResources Where ResourceID = rs.ResourceID) is null;


			UPDATE  TableResources SET 
				GroupID = (SELECT TOP(1) GroupID FROM @InsertedGroupID),
				ResourceType = COALESCE(r.ResourceType, TableResources.ResourceType),
				ResourceTitle = r.Title,
				ResourceURL = r.ResourceURL,
				SortOrder = COALESCE(r.SortOrder, TableResources.SortOrder),
				DateModified = @date
			FROM @ResourcesInput r
			WHERE TableResources.ResourceID = r.ResourceID;


			-- return the group and its resources
			SELECT 
				GroupID as groupID,
				CustomerID as customerID, 
				EventID as EventID, 
				GroupTitle as name, 
				GroupDescription as description, 
				SortOrder as sortOrder
			FROM TableResourceGroups
			WHERE GroupID = (SELECT TOP(1) GroupID FROM @InsertedGroupID)
			ORDER BY SortOrder asc;

			SELECT 
				GroupID as groupID,
				ResourceID as resourceID, 
				ResourceType as fileType, 
				ResourceTitle as name,
				ResourceURL as URL,  
				SortOrder as sortOrder
			FROM TableResources
			WHERE GroupID = (SELECT TOP(1) GroupID FROM @InsertedGroupID)
			ORDER BY SortOrder asc;
		end


--------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------


  -- update a  group if the @GroupID is not null
	ELSE
		begin
			-- delete resources from a group that are not included in @ResourcesInput
			Delete from TableResources
			WHERE ResourceID NOT IN (SELECT rr.ResourceID FROM @ResourcesInput rr where ResourceID is not null OR ResourceID != '') and TableResources.GroupID = @GroupID

			-- insert resources where ResourceID is null from @ResourcesInput
			INSERT INTO [dbo].[TableResources] (ResourceID, GroupID, EventID, ResourceType, ResourceTitle,ResourceURL, SortOrder, DateCreated, DateModified)

			SELECT LOWER(NewID()) as ResourceID, @GroupID, @EventID, rs.ResourceType, rs.Title, rs.ResourceURL,  rs.SortOrder, @date, @date
			FROM @ResourcesInput rs
			where rs.ResourceID IS NULL OR (Select ResourceID From TableResources Where ResourceID = rs.ResourceID) is null;

			-- update a group from the update collection
			UPDATE  TableResourceGroups SET 
				GroupTitle = @GroupTitle,
				GroupDescription = @GroupDescription,
				SortOrder = COALESCE(@SortOrder, TableResourceGroups.SortOrder),
				DateModified = @date
			WHERE TableResourceGroups.GroupID = @GroupID

			-- update resources from within a group that do belong to the update collection
			UPDATE  TableResources SET 
				GroupID = @GroupID,
				ResourceType = COALESCE(r.ResourceType, TableResources.ResourceType),
				ResourceTitle = r.Title,
				ResourceURL = r.ResourceURL,
				SortOrder = COALESCE(r.SortOrder, TableResources.SortOrder),
				DateModified = @date
			FROM @ResourcesInput r
			WHERE TableResources.ResourceID = r.ResourceID;

			-- return the group and its resources
			SELECT 
				GroupID as groupID,
				CustomerID as customerID, 
				EventID as EventID, 
				GroupTitle as name, 
				GroupDescription as description,
				SortOrder as sortOrder
			FROM TableResourceGroups
			WHERE GroupID = @GroupID
			ORDER BY SortOrder asc;

			SELECT 
				GroupID as groupID,
				ResourceID as resourceID, 
				ResourceType as fileType, 
				ResourceTitle as name,
				ResourceURL as URL,  
				SortOrder as sortOrder
			FROM TableResources
			WHERE GroupID = @GroupID
			ORDER BY SortOrder asc;
	
		end
