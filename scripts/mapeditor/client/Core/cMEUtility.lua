MapEditor.Utility = {}

MapEditor.Utility.DrawBounds = function(args)
	local b1 = args.bounds[1]
	local b2 = args.bounds[2]
	
	local transform = Transform3()
	transform:Translate(args.position)
	transform:Rotate(args.angle)
	transform:Translate(b1)
	transform:Scale(b2 - b1)
	Render:SetTransform(transform)
	
	if args.isSelected == true then
		MapEditor.Utility.boundsModelSelected:Draw()
	else
		MapEditor.Utility.boundsModel:Draw()
	end
	
	Render:ResetTransform()
end

MapEditor.Utility.DrawArea = function(position , size , thickness , color)
	local tVec = Vector2(thickness , thickness) * 0.5
	local Draw = function(a , b)
		if size.x < 0 and size.y < 0 then
			Render:FillArea(a + tVec , b - tVec - (a + tVec) , color)
		else
			Render:FillArea(a - tVec , b + tVec - (a - tVec) , color)
		end
	end
	
	local topLeft = position
	local topRight = position + Vector2(size.x , 0)
	local bottomLeft = position + Vector2(0 , size.y)
	local bottomRight = position + size
	Draw(topLeft , topRight , color)
	Draw(topLeft , bottomLeft , color)
	Draw(topRight , bottomRight , color)
	Draw(bottomLeft , bottomRight , color)
end

-- Create  models used for DrawBounds.

do
	local currentColor
	
	local V = function(x , y , z)
		return Vertex(Vector3(x , y , z) , currentColor)
	end
	
	currentColor = Color(128 , 128 , 128 , 96)
	MapEditor.Utility.boundsModel = Model.Create{
		-- Top
		V(0 , 1 , 0) , V(1 , 1 , 0) ,
		V(0 , 1 , 1) , V(1 , 1 , 1) ,
		V(0 , 1 , 0) , V(0 , 1 , 1) ,
		V(1 , 1 , 0) , V(1 , 1 , 1) ,
		-- Bottom
		V(0 , 0 , 0) , V(1 , 0 , 0) ,
		V(0 , 0 , 1) , V(1 , 0 , 1) ,
		V(0 , 0 , 0) , V(0 , 0 , 1) ,
		V(1 , 0 , 0) , V(1 , 0 , 1) ,
		-- Sides
		V(0 , 0 , 0) , V(0 , 1 , 0) ,
		V(1 , 0 , 0) , V(1 , 1 , 0) ,
		V(0 , 0 , 1) , V(0 , 1 , 1) ,
		V(1 , 0 , 1) , V(1 , 1 , 1) ,
	}
	MapEditor.Utility.boundsModel:SetTopology(Topology.LineList)
	
	currentColor = Color(64 , 255 , 64 , 192)
	MapEditor.Utility.boundsModelSelected = Model.Create{
		-- Top
		V(0 , 1 , 0) , V(1 , 1 , 0) ,
		V(0 , 1 , 1) , V(1 , 1 , 1) ,
		V(0 , 1 , 0) , V(0 , 1 , 1) ,
		V(1 , 1 , 0) , V(1 , 1 , 1) ,
		-- Bottom
		V(0 , 0 , 0) , V(1 , 0 , 0) ,
		V(0 , 0 , 1) , V(1 , 0 , 1) ,
		V(0 , 0 , 0) , V(0 , 0 , 1) ,
		V(1 , 0 , 0) , V(1 , 0 , 1) ,
		-- Sides
		V(0 , 0 , 0) , V(0 , 1 , 0) ,
		V(1 , 0 , 0) , V(1 , 1 , 0) ,
		V(0 , 0 , 1) , V(0 , 1 , 1) ,
		V(1 , 0 , 1) , V(1 , 1 , 1) ,
	}
	MapEditor.Utility.boundsModelSelected:SetTopology(Topology.LineList)
end
