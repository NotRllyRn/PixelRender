--[[
	CanvasDraw Module
	
	Created by: Ethanthegrand (@Ethanthegrand14)
	
	Last updated: 3/07/2022
	Version: 2.6.0
	
	Learn how to use the module here: https://devforum.roblox.com/t/canvasdraw-module-draw-pixels-lines-and-dynamic-shapes-on-your-screen/1624633
	API Reference Manual: https://devforum.roblox.com/t/api-reference-manual-for-canvasdraw-v232/1629460
	
	Copyright © 2022 - CanvasDraw
]]

local RunService = game:GetService("RunService")

local GradientCanvas = require(script:WaitForChild("GradientCanvas")) -- Credits to BoatBomber
local StringCompressor = require(script:WaitForChild("StringCompressor")) 

local CanvasDraw = {}
CanvasDraw.__index = CanvasDraw

-- These variables are only accessed by this module (do not edit)
local CurrentCanvas
local CurrentCanvasFrame
local CurrentCanvasResolutionX = 0
local CurrentCanvasResolutionY = 0
local SaveObjectResolutionLimit = Vector2.new(256, 256) -- Roblox string value character limits T-T
local CanvasResolutionLimit = Vector2.new(256, 256) -- Too many frames can cause rendering issues for roblox. So I think having this limit will help solve this problem for now.

-- Micro optimisations
local TableInsert = table.insert
local TableFind = table.find
local RoundN = math.round



--== MODULE PROPERTIES ==--

CanvasDraw.Resolution = Vector2.new(100, 100) -- Read only
CanvasDraw.CanvasColour = Color3.new(1, 1, 1) -- Read only

CanvasDraw.OutputWarnings = true
CanvasDraw.AutoUpdate = true


--== MODULE EVENTS ==--

CanvasDraw.Heartbeat = RunService.Heartbeat


--== BUILT-IN FUNCTIONS ==--

local function GetRange(A, B)
	if A > B then
		return RoundN(A - B), -1
	else
		return RoundN(B - A), 1
	end
end

local function RoundPoint(Point)
	local X = RoundN(Point.X)
	local Y = RoundN(Point.Y)
	return Vector2.new(X, Y)
end

local function PointToPixelIndex(Point, Resolution)
	local X = RoundN(Point.X)
	local Y = RoundN(Point.Y)
	local ResX = Resolution.X
	local ResY = Resolution.Y
	
	if X > 0 and Y > 0 and X <= ResX and Y <= ResY then
		local Index = X + ((Y - 1) * ResX)
		return Index
	end
end

local function XYToPixelIndex(X, Y, ResolutionX)
	local Index = X + ((Y - 1) * ResolutionX)
	return Index
end

local function GetIndexForCanvasPixels(X, Y)
	return X + ((Y - 1) * CurrentCanvasResolutionX)
end

local function OutputWarn(Message)
	if CanvasDraw.OutputWarnings then
		warn("(!) CanvasDraw Module Warning: '" .. Message .. "'")
	end
end

local function CheckForCanvas(FunctionPurpose)
	if not CurrentCanvas then
		OutputWarn("Failed to " .. FunctionPurpose .. " (There is no canvas). Please create a canvas first before calling this specific function")
		return true
	end
end

--== MODULE FUCNTIONS ==--


-- Canvas functions

function CanvasDraw.CreateCanvas(Frame: GuiObject, Resolution: Vector2, CanvasColour: Color3, BlurEnabled: boolean): {}
	local ReturnPoints = {}

	if CurrentCanvas then
		OutputWarn("Failed to create canvas (A canvas has already been created). Please use the DestroyCanvas() function if you wish to remove the current canvas.")
		return
	end

	-- Optional variable defaults

	if CanvasColour then
		CanvasDraw.CanvasColour = CanvasColour 
	else
		CanvasDraw.CanvasColour = Frame.BackgroundColor3
	end

	if Resolution then
		if Resolution.X > CanvasResolutionLimit.X or Resolution.Y > CanvasResolutionLimit.Y then
			OutputWarn("A canvas cannot be built with a resolution larger than " .. CanvasResolutionLimit.X .. " x " .. CanvasResolutionLimit.Y .. ".")
			Resolution = CanvasResolutionLimit
		end
		CanvasDraw.Resolution = Resolution
	end

	CanvasDraw.CurrentCanvasResolutionX = CanvasDraw.Resolution.X
	CanvasDraw.CurrentCanvasResolutionY = CanvasDraw.Resolution.Y

	-- Create the canvas
	CanvasDraw.CurrentCanvas = GradientCanvas.new(CurrentCanvasResolutionX, CurrentCanvasResolutionY, BlurEnabled)
	CanvasDraw.CurrentCanvas:SetParent(Frame)
	
	CanvasDraw.CurrentCanvasFrame = Frame

	for Y = 1, CurrentCanvasResolutionY do
		for X = 1, CurrentCanvasResolutionX do
			TableInsert(ReturnPoints, Vector2.new(X, Y))
			CanvasDraw:SetPixel(X, Y, CanvasDraw.CanvasColour)
		end
	end
	
	CanvasDraw.CurrentCanvas:Render()

	return ReturnPoints
end

function CanvasDraw.DestroyCanvas()
	if CheckForCanvas("destroy canvas") then return end

	CurrentCanvas:Destroy()
	CurrentCanvas = nil
	CurrentCanvasFrame = nil
end

function CanvasDraw.FillCanvas(Colour: Color3)
	if CheckForCanvas("fill canvas") then return end

	for Y = 1, CurrentCanvasResolutionY do
		for X = 1, CurrentCanvasResolutionX do
			CanvasDraw.SetPixel(X, Y, Colour)
		end
	end
end

function CanvasDraw.ClearCanvas()
	if CheckForCanvas("clear canvas") then return end
	CanvasDraw.FillCanvas(CanvasDraw.CanvasColour)
end

function CanvasDraw.Update()
	if CheckForCanvas("update canvas") then return end
	CurrentCanvas:Render()
end


-- Fetch functions

function CanvasDraw.GetPixel(Point: Vector2): Color3
	return CurrentCanvas:GetPixel(Point.X, Point.Y)
end

function CanvasDraw.GetPixelXY(X: number, Y: number): Color3
	return CurrentCanvas:GetPixel(X, Y)
end

function CanvasDraw.GetPixels(PointA: Vector2, PointB: Vector2): {}
	if CheckForCanvas("get pixels") then return end

	local PixelsArray = {}

	-- Get the all pixels between PointA and PointB
	if PointA and PointB then
		local DistX, FlipMultiplierX = GetRange(PointA.X, PointB.X)
		local DistY, FlipMultiplierY = GetRange(PointA.Y, PointB.Y)

		for Y = 0, DistY do
			for X = 0, DistX do
				local Point = Vector2.new(PointA.X + X * FlipMultiplierX, PointA.Y + Y * FlipMultiplierY)
				local Pixel = CanvasDraw.GetPixel(Point)
				if Pixel then
					TableInsert(PixelsArray, Pixel)
				end
			end
		end
	else
		-- If there isn't any points in the paramaters, then return all pixels in the canvas
		for Y = 1, CurrentCanvasResolutionY do
			for X = 1, CurrentCanvasResolutionX do
				local Pixel = CanvasDraw.GetPixelXY(X, Y)
				if Pixel then
					TableInsert(PixelsArray, Pixel)
				end
			end
		end
	end
	
	return PixelsArray
end

function CanvasDraw.GetPoints(PointA: Vector2, PointB: Vector2): {}
	if CheckForCanvas("get points") then return end

	local PointsArray = {}

	-- Get all points between PointA and PointB
	if PointA and PointB then
		local DistX, FlipMultiplierX = GetRange(PointA.X, PointB.X)
		local DistY, FlipMultiplierY = GetRange(PointA.Y, PointB.Y)

		for Y = 0, DistY do
			for X = 0, DistX do
				local Point = Vector2.new(PointA.X + X * FlipMultiplierX, PointA.Y + Y * FlipMultiplierY)

				TableInsert(PointsArray, Point)
			end
		end
	else
		-- If there isn't any points in the paramaters, then return all pixel points in the canvas
		for Y = 1, CanvasDraw.Resolution.Y do
			for X = 1, CurrentCanvasResolutionX do
				TableInsert(PointsArray, Vector2.new(X, Y))
			end
		end
	end
	return PointsArray
end

function CanvasDraw.GetPointFromMouse(): Vector2?
	if RunService:IsClient() then
		local UserInputService = game:GetService("UserInputService")
		local MousePos = UserInputService:GetMouseLocation()
		local MousePoint = Vector2.new(MousePos.X, MousePos.Y) - CurrentCanvasFrame.AbsolutePosition
		local CanvasFrameSize = CurrentCanvasFrame.GradientCanvas.AbsoluteSize
		
		-- Roblox top bar exist T-T
		MousePoint -= Vector2.new(0, 36)
		
		-- Convert the mouse location into canvas point
		local TransformedPoint = ((MousePoint) / (CanvasFrameSize)) * CanvasDraw.Resolution 
		
		TransformedPoint += Vector2.new(1 / CurrentCanvasResolutionX, 1 / CurrentCanvasResolutionY) * CanvasDraw.Resolution * 0.5
		
		-- Make sure everything is aligned when the canvas is at different aspect ratios
		local RatioDifference = Vector2.new(CurrentCanvasFrame.AbsoluteSize.X / CanvasFrameSize.X, CurrentCanvasFrame.AbsoluteSize.Y / CanvasFrameSize.Y) - Vector2.new(1, 1)
		TransformedPoint -= (RatioDifference / 2) * CanvasDraw.Resolution
		
		TransformedPoint = RoundPoint(TransformedPoint)
		
		-- If the point is within the canvas, return it.
		if TransformedPoint.X > 0 and TransformedPoint.Y > 0 and TransformedPoint.X <= CurrentCanvasResolutionX and TransformedPoint.Y <= CurrentCanvasResolutionY then
			return TransformedPoint
		end
	else
		OutputWarn("Failed to get point from mouse (you cannot use this function on the server. Please call this function from a LocalScript).")
	end
end


-- Image data functions

function CanvasDraw.CreateImageDataFromCanvas(PointA: Vector2, PointB: Vector2): {}
	if CheckForCanvas("create image data from canvas") then return end

	-- Set the default points to be the whole canvas corners
	if not PointA and not PointB then
		PointA = Vector2.new(1, 1)
		PointB = CanvasDraw.Resolution
	end

	local ImageResolutionX = GetRange(PointA.X, PointB.X) + 1
	local ImageResolutionY = GetRange(PointA.Y, PointB.Y) + 1

	local ColoursData = CanvasDraw.GetPixels(PointA, PointB)
	local AlphasData = {}

	-- Canvas has no transparency. So all alpha values will be 255
	for i = 1, #ColoursData do
		TableInsert(AlphasData, 255)
	end

	return {ImageColours = ColoursData, ImageAlphas = AlphasData, ImageResolution = Vector2.new(ImageResolutionX, ImageResolutionY)}
end

function CanvasDraw.CreateSaveObject(ImageData: Table, InstantCreate: boolean): Instance
	if CheckForCanvas("create SaveObject") then return end

	if ImageData.ImageResolution.X > SaveObjectResolutionLimit.X and ImageData.ImageResolution.Y > SaveObjectResolutionLimit.Y then
		OutputWarn("Failed to create an image save object (ImageData too large). Please try to keep the resolution of the image no higher than '" .. SaveObjectResolutionLimit.X .. " x " .. SaveObjectResolutionLimit.Y .. "'.")
		return
	end

	local FastWaitCount = 0

	local function FastWait(Count)
		if FastWaitCount >= Count then
			FastWaitCount = 0
			RunService.Heartbeat:Wait()
		else
			FastWaitCount += 1
		end
	end

	local function ConvertColoursToListString(Colours)
		local ColoursListString = ""

		for i, Colour in pairs(Colours) do
			local ColourR = RoundN(Colour.R * 255)
			local ColourG = RoundN(Colour.G * 255)
			local ColourB = RoundN(Colour.B * 255)

			local StringSegment = tostring(ColourR) .. "," .. tostring(ColourG) .. "," .. tostring(ColourB)
			ColoursListString = ColoursListString .. StringSegment
			if i ~= #Colours then
				ColoursListString = ColoursListString .. "S"
			end

			if not InstantCreate then
				FastWait(100)
			end
		end

		return ColoursListString
	end

	local function ConvertAlphasToListString(Alphas)
		local AlphasListString = ""

		for i, Alpha in pairs(Alphas) do
			AlphasListString = AlphasListString .. Alpha

			if i ~= #Alphas then
				AlphasListString = AlphasListString .. "S"
			end

			if not InstantCreate then
				FastWait(200)
			end
		end

		return AlphasListString
	end

	local ImageColoursString = ConvertColoursToListString(ImageData.ImageColours)
	local ImageAlphasString = ConvertAlphasToListString(ImageData.ImageAlphas)
	
	local CompressedImageColoursString = StringCompressor.Compress(ImageColoursString)
	local CompressedImageAlphasString = StringCompressor.Compress(ImageAlphasString)

	local NewSaveObject = Instance.new("Folder")
	NewSaveObject.Name = "NewSave"

	NewSaveObject:SetAttribute("ImageColours", CompressedImageColoursString)
	NewSaveObject:SetAttribute("ImageAlphas", CompressedImageAlphasString)
	NewSaveObject:SetAttribute("ImageResolution", ImageData.ImageResolution)

	return NewSaveObject
end

function CanvasDraw.GetPixelFromImage(ImageData: Table, Point: Vector2)
	local PixelIndex = PointToPixelIndex(Point, ImageData.ImageResolution) -- Convert the point into an index for the array of colours

	local PixelColour = ImageData.ImageColours[PixelIndex]
	local PixelAlpha = ImageData.ImageAlphas[PixelIndex]

	return PixelColour, PixelAlpha
end

function CanvasDraw.GetPixelFromImageXY(ImageData: Table, X: number, Y: number)
	local PixelIndex = XYToPixelIndex(X, Y, ImageData.ImageResolution.X) -- Convert the coordinates into an index for the array of colours

	local PixelColour = ImageData.ImageColours[PixelIndex]
	local PixelAlpha = ImageData.ImageAlphas[PixelIndex]

	return PixelColour, PixelAlpha
end

function CanvasDraw.DrawImage(ImageData: Table, Point: Vector2, TransparencyEnabled: boolean?): {}
	if CheckForCanvas("drawimage") then return end

	local ReturnPixelsPoints = {}

	local X = Point.X
	local Y = Point.Y

	local ImageResolutionX = ImageData.ImageResolution.X
	local ImageResolutionY = ImageData.ImageResolution.Y
	local ImageColours = ImageData.ImageColours
	local ImageAlphas = ImageData.ImageAlphas

	if not TransparencyEnabled then
		-- Draw image with no transparency
		for ImgX = 1, ImageResolutionX do
			for ImgY = 1, ImageResolutionY do
				local ImgPixelColour = ImageColours[ImgX + ((ImgY - 1) * ImageResolutionX)]
				
				local Point = Vector2.new(X + ImgX - 1, Y + ImgY - 1)
				CanvasDraw.DrawPixel(Point, ImgPixelColour)
				
				table.insert(ReturnPixelsPoints, Point)
			end
		end
	else
		-- Draw image with transaprency (more expensive)
		for ImgX = 1, ImageResolutionX do
			for ImgY = 1, ImageResolutionY do
				local Point = Vector2.new(X + ImgX - 1, Y + ImgY - 1)

				local ImgPixelIndex = ImgX + ((ImgY - 1) * ImageResolutionX)

				local BgColour = CanvasDraw.GetPixel(Point)

				local ImgPixelColour = ImageColours[ImgPixelIndex]
				local ImgPixelAlpha = ImageAlphas[ImgPixelIndex]

				
				CanvasDraw.DrawPixel(Point, ImgPixelColour)

				table.insert(ReturnPixelsPoints, Point)
			end
		end
	end
	

	return ReturnPixelsPoints
end

function CanvasDraw.DrawImageXY(ImageData: Table, X: number, Y: number, TransparencyEnabled: boolean?)
	if CheckForCanvas("drawimage (xy)") then return end

	local ImageResolutionX = ImageData.ImageResolution.X
	local ImageResolutionY = ImageData.ImageResolution.Y
	local ImageColours = ImageData.ImageColours
	local ImageAlphas = ImageData.ImageAlphas
	
	if not TransparencyEnabled then
		-- Draw image with no transparency
		for ImgX = 1, ImageResolutionX do
			for ImgY = 1, ImageResolutionY do
				local ImgPixelColour = ImageColours[ImgX + ((ImgY - 1) * ImageResolutionX)]
				CanvasDraw.SetPixel(X + ImgX - 1, Y + ImgY - 1, ImgPixelColour)
			end
		end
	else
		-- Draw image with transaprency (more expensive)
		for ImgX = 1, ImageResolutionX do
			for ImgY = 1, ImageResolutionY do
				local CanvasX = X + ImgX - 1
				local CanvasY = Y + ImgY - 1
				
				local ImgPixelIndex = ImgX + ((ImgY - 1) * ImageResolutionX)
				
				local BgColour = CanvasDraw.GetPixelXY(CanvasX, CanvasY)
				
				local ImgPixelColour = ImageColours[ImgPixelIndex]
				local ImgPixelAlpha = ImageAlphas[ImgPixelIndex]
				
				CanvasDraw.SetPixel(CanvasX, CanvasY, BgColour:Lerp(ImgPixelColour, ImgPixelAlpha / 255))
			end
		end
	end
end

function CanvasDraw.DrawDistortedImage(ImageData: Table, Point: Vector2, Scale: Vector2, SkewOffset: Vector2, TransparencyEnabled: boolean, ColourTint: Color3, TintAmount: number): {}
	local ReturnPixelPoints = {}

	-- Defaults
	if not TintAmount then
		TintAmount = 0.5
	end

	if not Scale then
		Scale = Vector2.new(1, 1)
	end

	if not SkewOffset then
		SkewOffset = Vector2.new(0, 0)
	end

	if not Point then
		Point = Vector2.new(1, 1)
	end

	-- Scale strech
	local LengthX = ImageData.ImageResolution.X * Scale.X
	local LengthY = ImageData.ImageResolution.Y * Scale.Y

	-- Draw the pixels
	if TransparencyEnabled or type(TransparencyEnabled) == "nil" then
		-- Draw the distorted image with transparency blending
		for X = 1, LengthX do
			for Y = 1, LengthY do
				local DrawPoint = Point -- Origin
				DrawPoint += Vector2.new(X - 1, Y - 1)
				DrawPoint += Vector2.new(Y * SkewOffset.X, X * SkewOffset.Y) / 45 -- Skew the image

				local ImageColourSamplePoint = Vector2.new(X / Scale.X, Y / Scale.Y)
				ImageColourSamplePoint = RoundPoint(ImageColourSamplePoint)

				-- Draw the pixel
				local PixelColour, PixelAlpha = CanvasDraw.GetPixelFromImage(ImageData, ImageColourSamplePoint)

				if ColourTint then
					PixelColour = PixelColour:Lerp(ColourTint, TintAmount)
				end

				-- Blend image with background for transparency
				local OldPixelColour = CanvasDraw.GetPixel(DrawPoint)

				if OldPixelColour and PixelAlpha then
					CanvasDraw.DrawPixel(DrawPoint, OldPixelColour:Lerp(PixelColour, PixelAlpha / 255))
				end

				TableInsert(ReturnPixelPoints, DrawPoint)
			end
		end
	else
		-- Draw the image with no transparency
		for X = 1, LengthX do
			for Y = 1, LengthY do
				local DrawPoint = Point -- Origin
				DrawPoint += Vector2.new(X - 1, Y - 1)
				DrawPoint += Vector2.new(Y * SkewOffset.X, X * SkewOffset.Y) / 45 -- Skew the image

				local ImageColourSamplePoint = Vector2.new(X / Scale.X, Y / Scale.Y)
				ImageColourSamplePoint = RoundPoint(ImageColourSamplePoint)

				-- Draw the pixel
				local PixelColour = CanvasDraw.GetPixelFromImage(ImageData, ImageColourSamplePoint)

				if ColourTint then
					PixelColour = PixelColour:Lerp(ColourTint, TintAmount)
				end

				if PixelColour then
					CanvasDraw.DrawPixel(DrawPoint, PixelColour)
				end

				TableInsert(ReturnPixelPoints, DrawPoint)
			end
		end
	end
	
	return ReturnPixelPoints
end

function CanvasDraw.GetImageDataFromSaveObject(SaveObject: Folder): {}
	local SaveDataImageColours = SaveObject:GetAttribute("ImageColours")
	local SaveDataImageAlphas = SaveObject:GetAttribute("ImageAlphas")
	local SaveDataImageResolution = SaveObject:GetAttribute("ImageResolution")
	
	-- Decompress the data
	local DecompressedSaveDataImageColours = StringCompressor.Decompress(SaveDataImageColours)
	local DecompressedSaveDataImageAlphas = StringCompressor.Decompress(SaveDataImageAlphas)


	-- Get a single pixel colour info form the data
	local PixelDataColoursString = string.split(DecompressedSaveDataImageColours, "S")
	local PixelDataAlphasString = string.split(DecompressedSaveDataImageAlphas, "S")

	local PixelColours = {}
	local PixelAlphas = {}

	for i, PixelColourString in pairs(PixelDataColoursString) do
		local RGBValues = string.split(PixelColourString, ",")
		local PixelColour = Color3.fromRGB(table.unpack(RGBValues))

		local PixelAlpha = tonumber(PixelDataAlphasString[i])

		TableInsert(PixelColours, PixelColour)
		TableInsert(PixelAlphas, PixelAlpha)
	end

	-- Convert the SaveObject into image data
	local ImageData = {ImageColours = PixelColours, ImageAlphas = PixelAlphas, ImageResolution = SaveDataImageResolution}

	return ImageData
end


-- Draw functions

function CanvasDraw.ClearPixels(PixelPoints: table)
	if CheckForCanvas("clear pixels") then return end

	CanvasDraw.FillPixels(PixelPoints, CanvasDraw.CanvasColour)
end

function CanvasDraw.FillPixels(Points: table, Colour: Color3)
	if CheckForCanvas("fill pixels") then return end

	for i, Point in pairs(Points) do
		CanvasDraw.DrawPixel(Point, Colour)
	end
end

function CanvasDraw.FloodFill(Point: Vector2, Colour: Color3): {}
	if CheckForCanvas("flood fill") then return end
	
	Point = RoundPoint(Point)

	local OriginColour = CanvasDraw.GetPixel(Point)

	local ReturnPointsArray = {}

	local function CheckNeighbours(OriginPoint)
		local function CheckPixel(PointToCheck) 
			local PointToCheckX = PointToCheck.X
			local PointToCheckY = PointToCheck.Y
			
			-- Check if this point is within the canvas
			if PointToCheckX > 0 and PointToCheckY > 0 and PointToCheckX <= CurrentCanvasResolutionX and PointToCheckY <= CurrentCanvasResolutionY then
				-- Check if there is a pixel and it can be coloured
				if not TableFind(ReturnPointsArray, PointToCheck) then
					local PixelColourToCheck = CanvasDraw.GetPixel(PointToCheck)
					if PixelColourToCheck == OriginColour then
						TableInsert(ReturnPointsArray, PointToCheck)

						-- Colour the pixel
						CanvasDraw.SetPixel(PointToCheckX, PointToCheckY, Colour)

						CheckNeighbours(PointToCheck)
					end
				end
			end
		end

		-- Check all four directions of the pixel
		local PointUp = OriginPoint + Vector2.new(0, -1)
		CheckPixel(PointUp)

		local PointDown = OriginPoint + Vector2.new(0, 1)
		CheckPixel(PointDown)

		local PointLeft = OriginPoint + Vector2.new(-1, 0)
		CheckPixel(PointLeft)

		local PointRight = OriginPoint + Vector2.new(1, 0)
		CheckPixel(PointRight)
	end

	CheckNeighbours(Point)

	return ReturnPointsArray
end

function CanvasDraw.DrawPixel(Point: Vector2, Colour: Color3): Vector2
	local X = RoundN(Point.X)
	local Y = RoundN(Point.Y)

	if X > 0 and Y > 0 and X <= CurrentCanvasResolutionX and Y <= CurrentCanvasResolutionY then	
		CurrentCanvas:SetPixel(X, Y, Colour)
		return Point	
	end
end

function CanvasDraw.SetPixel(X: number, Y: number, Colour: Color3) -- A raw and performant method to draw pixels (much faster than `DrawPixel()`)
	CurrentCanvas:SetPixel(X, Y, Colour)
end

function CanvasDraw.DrawCircle(Point: Vector2, Radius: number, Colour: Color3, Fill: boolean): {}
	if CheckForCanvas("draw circle") then return end
	
	local X = RoundN(Point.X)
	local Y = RoundN(Point.Y)
	
	local PointsArray = {}
	
	-- Draw the circle
	local dx, dy, err = Radius, 0, 1 - Radius
	
	local function CreatePixelForCircle(DrawPoint)
		CanvasDraw.DrawPixel(DrawPoint, Colour)
		TableInsert(PointsArray, DrawPoint)
	end
	
	local function CreateLineForCircle(PointB, PointA)
		local Line = CanvasDraw.DrawRectangle(PointA, PointB, Colour, true)
		
		for i, Point in pairs(Line) do
			TableInsert(PointsArray, Point)
		end
	end
	
	if Fill or type(Fill) == "nil" then
		while dx >= dy do -- Filled circle
			CreateLineForCircle(Vector2.new(X + dx, Y + dy), Vector2.new(X - dx, Y + dy))
			CreateLineForCircle(Vector2.new(X + dx, Y - dy), Vector2.new(X - dx, Y - dy))
			CreateLineForCircle(Vector2.new(X + dy, Y + dx), Vector2.new(X - dy, Y + dx))
			CreateLineForCircle(Vector2.new(X + dy, Y - dx), Vector2.new(X - dy, Y - dx))
			
			dy = dy + 1
			if err < 0 then
				err = err + 2 * dy + 1
			else
				dx, err = dx - 1, err + 2 * (dy - dx) + 1
			end
		end
	else
		while dx >= dy do -- Circle outline
			CreatePixelForCircle(Vector2.new(X + dx, Y + dy))
			CreatePixelForCircle(Vector2.new(X - dx, Y + dy))
			CreatePixelForCircle(Vector2.new(X + dx, Y - dy))
			CreatePixelForCircle(Vector2.new(X - dx, Y - dy))
			CreatePixelForCircle(Vector2.new(X + dy, Y + dx))
			CreatePixelForCircle(Vector2.new(X - dy, Y + dx))
			CreatePixelForCircle(Vector2.new(X + dy, Y - dx))
			CreatePixelForCircle(Vector2.new(X - dy, Y - dx))

			dy = dy + 1
			if err < 0 then
				err = err + 2 * dy + 1
			else
				dx, err = dx - 1, err + 2 * (dy - dx) + 1
			end
		end
	end

	return PointsArray
end

function CanvasDraw.DrawCircleXY(X: number, Y: number, Radius: number, Colour: Color3, Fill: boolean)
	if CheckForCanvas("draw circle (xy)") then return end
	
	if X + Radius > CurrentCanvasResolutionY or Y + Radius > CurrentCanvasResolutionY or X - Radius < 1 or Y - Radius < 1 then
		OutputWarn("Circle (xy) is exceeding bounds! Drawing cancelled.")
		return
	end

	-- Draw the circle
	local dx, dy, err = Radius, 0, 1 - Radius

	local function CreatePixelForCircle(DrawX, DrawY)
		CanvasDraw.SetPixel(DrawX, DrawY, Colour)
	end

	local function CreateLineForCircle(EndX, StartX, Y)
		for DrawX = 0, EndX - StartX do
			CanvasDraw.SetPixel(StartX + DrawX, Y, Colour)
		end
	end

	if Fill or type(Fill) == "nil" then
		while dx >= dy do -- Filled circle
			CreateLineForCircle(X + dx, X - dx, Y + dy)
			CreateLineForCircle(X + dx, X - dx, Y - dy)
			CreateLineForCircle(X + dy, X - dy, Y + dx)
			CreateLineForCircle(X + dy, X - dy, Y - dx)

			dy = dy + 1
			if err < 0 then
				err = err + 2 * dy + 1
			else
				dx, err = dx - 1, err + 2 * (dy - dx) + 1
			end
		end
	else
		while dx >= dy do -- Circle outline
			CreatePixelForCircle(X + dx, Y + dy)
			CreatePixelForCircle(X - dx, Y + dy)
			CreatePixelForCircle(X + dx, Y - dy)
			CreatePixelForCircle(X - dx, Y - dy)
			CreatePixelForCircle(X + dy, Y + dx)
			CreatePixelForCircle(X - dy, Y + dx)
			CreatePixelForCircle(X + dy, Y - dx)
			CreatePixelForCircle(X - dy, Y - dx)

			dy = dy + 1
			if err < 0 then
				err = err + 2 * dy + 1
			else
				dx, err = dx - 1, err + 2 * (dy - dx) + 1
			end
		end
	end
end

function CanvasDraw.DrawRectangle(PointA: Vector2, PointB: Vector2, Colour: Color3, Fill: boolean): {}
	if CheckForCanvas("draw rectange") then return end
	
	local ReturnPoints = {}

	local X1 = RoundN(PointA.X)
	local Y1 = RoundN(PointA.Y)
	local X2 = RoundN(PointB.X)
	local Y2 = RoundN(PointB.Y)

	local RangeX = math.abs(X2 - X1)
	local RangeY = math.abs(Y2 - Y1)

	if Fill or type(Fill) == "nil" then
		-- Fill every pixel
		for PlotX = 0, RangeX do
			for PlotY = 0, RangeY do
				local DrawPoint = Vector2.new(X1 + PlotX, Y1 + PlotY)
				CanvasDraw.DrawPixel(DrawPoint, Colour)
				TableInsert(ReturnPoints, DrawPoint)
			end
		end
	else
		-- Just draw the outlines
		for PlotX = 0, RangeX do -- Top and bottom
			local DrawPointUp = Vector2.new(X1 + PlotX, Y1)
			local DrawPointDown = Vector2.new(X1 + PlotX, Y2)
			
			CanvasDraw.DrawPixel(DrawPointUp, Colour)
			CanvasDraw.DrawPixel(DrawPointDown, Colour)
			
			
			TableInsert(ReturnPoints, DrawPointUp)
			TableInsert(ReturnPoints, DrawPointDown)
		end

		for PlotY = 0, RangeY do -- Left and right
			local DrawPointLeft = Vector2.new(X1, Y1 + PlotY)
			local DrawPointRight = Vector2.new(X2, Y1 + PlotY)

			CanvasDraw.DrawPixel(DrawPointLeft, Colour)
			CanvasDraw.DrawPixel(DrawPointRight, Colour)


			TableInsert(ReturnPoints, DrawPointLeft)
			TableInsert(ReturnPoints, DrawPointRight)
		end
	end
	
	return ReturnPoints
end

function CanvasDraw.DrawRectangleXY(X1: number, Y1: number, X2: number, Y2: number, Colour: Color3, Fill: boolean)
	if CheckForCanvas("draw rectange") then return end
	
	local RangeX = math.abs(X2 - X1)
	local RangeY = math.abs(Y2 - Y1)
	
	if Fill or type(Fill) == "nil" then
		-- Fill every pixel
		for PlotX = 0, RangeX do
			for PlotY = 0, RangeY do
				CanvasDraw.SetPixel(X1 + PlotX, Y1 + PlotY, Colour)
			end
		end
	else
		-- Just draw the outlines
		for PlotX = 0, RangeX do -- Top and bottom
			CanvasDraw.SetPixel(X1 + PlotX, Y1, Colour)
			CanvasDraw.SetPixel(X1 + PlotX, Y2, Colour)
		end
		
		for PlotY = 0, RangeY do -- Left and right
			CanvasDraw.SetPixel(X1, Y1 + PlotY, Colour)
			CanvasDraw.SetPixel(X2, Y1 + PlotY, Colour)
		end
	end
end

function CanvasDraw.DrawTriangle(PointA: Vector2, PointB: Vector2, PointC: Vector2, Colour: Color3, Fill: boolean): {}
	if CheckForCanvas("draw triangle") then return end
	
	local ReturnPoints = {}
	
	if typeof(Fill) == "nil" or Fill == true then
		local X1 = PointA.X
		local X2 = PointB.X
		local X3 = PointC.X
		local Y1 = PointA.Y
		local Y2 = PointB.Y
		local Y3 = PointC.Y

		local CurrentY1 = Y1
		local CurrentY2 = Y2
		local CurrentY3 = Y3

		local CurrentX1 = X1
		local CurrentX2 = X2
		local CurrentX3 = X3

		-- Sort the vertices based on Y ascending
		if Y3 < Y2 then
			Y3 = CurrentY2
			Y2 = CurrentY3
			X3 = CurrentX2
			X2 = CurrentX3

			CurrentY3 = Y3
			CurrentY2 = Y2
			CurrentX3 = X3
			CurrentX2 = X2
		end	
		if Y3 < Y1 then
			Y3 = CurrentY1
			Y1 = CurrentY3
			X3 = CurrentX1
			X1 = CurrentX3

			CurrentY1 = Y1
			CurrentY3 = Y3
			CurrentX1 = X1
			CurrentX3 = X3
		end	
		if Y2 < Y1 then
			Y2 = CurrentY1
			Y1 = CurrentY2
			X2 = CurrentX1
			X1 = CurrentX2
		end

		local function PlotLine(StartX, EndX, Y, TriY)
			local Range = EndX - StartX

			for X = 1, Range do
				local Point = Vector2.new(StartX + X, TriY + Y)
				CanvasDraw.DrawPixel(Point, Colour)
				
				TableInsert(ReturnPoints, Point)
			end
		end

		local function DrawBottomFlatTriangle(TriX1, TriY1, TriX2, TriY2, TriX3, TriY3) 
			--[[
				TriX1, TriY1 - Triangle top point
				TriX2, TriY2 - Triangle bottom left corner
				TriX3, TriY3 - Triangle bottom right corner
			]]
			local invslope1 = (TriX2 - TriX1) / (TriY2 - TriY1)
			local invslope2 = (TriX3 - TriX1) / (TriY3 - TriY1)

			local curx1 = TriX1
			local curx2 = TriX1

			for Y = 0, TriY3 - TriY1 do
				PlotLine(math.floor(curx1), math.floor(curx2), Y, TriY1)
				curx1 += invslope1
				curx2 += invslope2
			end
		end

		local function DrawTopFlatTriangle(TriX1, TriY1, TriX2, TriY2, TriX3, TriY3)	
			--[[
				TriX1, TriY1 - Triangle top left corner
				TriX2, TriY2 - Triangle top right corner
				TriX3, TriY3 - Triangle bottom point
			]]
			local invslope1 = (TriX3 - TriX1) / (TriY3 - TriY1)
			local invslope2 = (TriX3 - TriX2) / (TriY3 - TriY2)

			local curx1 = TriX3
			local curx2 = TriX3

			for Y = 0, TriY3 - TriY1 do
				PlotLine(math.floor(curx1), math.floor(curx2), -Y, TriY3)
				curx1 -= invslope1
				curx2 -= invslope2
			end
		end

		local TriMidX = X1 + (Y2 - Y1) / (Y3 - Y1) * (X3 - X1)

		if TriMidX < X2 then
			DrawBottomFlatTriangle(X1, Y1, TriMidX, Y2, X2, Y2)
			DrawTopFlatTriangle(TriMidX, Y2, X2, Y2, X3, Y3)
		else
			DrawBottomFlatTriangle(X1, Y1, X2, Y2, TriMidX, Y2)
			DrawTopFlatTriangle(X2, Y2, TriMidX, Y2, X3, Y3)
		end
	end
	
	local LineA = CanvasDraw.DrawLine(PointA, PointB, Colour)
	local LineB = CanvasDraw.DrawLine(PointB, PointC, Colour)
	local LineC = CanvasDraw.DrawLine(PointC, PointA, Colour)
	
	for Point in pairs(LineA) do
		TableInsert(ReturnPoints, Point)
	end
	for Point in pairs(LineB) do
		TableInsert(ReturnPoints, Point)
	end
	for Point in pairs(LineC) do
		TableInsert(ReturnPoints, Point)
	end
	
	return ReturnPoints
end


function CanvasDraw.DrawTriangleXY(X1: number, Y1: number, X2: number, Y2: number, X3: number, Y3: number, Colour: Color, Fill: boolean)
	if CheckForCanvas("draw triangle (xy)") then return end
	
	if Fill or typeof(Fill) == "nil" then
		local CurrentY1 = Y1
		local CurrentY2 = Y2
		local CurrentY3 = Y3
		
		local CurrentX1 = X1
		local CurrentX2 = X2
		local CurrentX3 = X3
		
		-- Sort the vertices based on Y ascending
		if Y3 < Y2 then
			Y3 = CurrentY2
			Y2 = CurrentY3
			X3 = CurrentX2
			X2 = CurrentX3
			
			CurrentY3 = Y3
			CurrentY2 = Y2
			CurrentX3 = X3
			CurrentX2 = X2
		end	
		if Y3 < Y1 then
			Y3 = CurrentY1
			Y1 = CurrentY3
			X3 = CurrentX1
			X1 = CurrentX3

			CurrentY1 = Y1
			CurrentY3 = Y3
			CurrentX1 = X1
			CurrentX3 = X3
		end	
		if Y2 < Y1 then
			Y2 = CurrentY1
			Y1 = CurrentY2
			X2 = CurrentX1
			X1 = CurrentX2
		end
		
		local function PlotLine(StartX, EndX, Y, TriY)
			local Range = EndX - StartX

			for X = 1, Range do
				CanvasDraw.SetPixel(StartX + X, TriY + Y, Colour)
			end
		end
		
		local function DrawBottomFlatTriangle(TriX1, TriY1, TriX2, TriY2, TriX3, TriY3) 
			--[[
				TriX1, TriY1 - Triangle top point
				TriX2, TriY2 - Triangle bottom left corner
				TriX3, TriY3 - Triangle bottom right corner
			]]
			local invslope1 = (TriX2 - TriX1) / (TriY2 - TriY1)
			local invslope2 = (TriX3 - TriX1) / (TriY3 - TriY1)

			local curx1 = TriX1
			local curx2 = TriX1
			
			for Y = 0, TriY3 - TriY1 do
				PlotLine(math.floor(curx1), math.floor(curx2), Y, TriY1)
				curx1 += invslope1
				curx2 += invslope2
			end
		end
		
		local function DrawTopFlatTriangle(TriX1, TriY1, TriX2, TriY2, TriX3, TriY3)	
			--[[
				TriX1, TriY1 - Triangle top left corner
				TriX2, TriY2 - Triangle top right corner
				TriX3, TriY3 - Triangle bottom point
			]]
			local invslope1 = (TriX3 - TriX1) / (TriY3 - TriY1)
			local invslope2 = (TriX3 - TriX2) / (TriY3 - TriY2)

			local curx1 = TriX3
			local curx2 = TriX3

			for Y = 0, TriY3 - TriY1 do
				PlotLine(math.floor(curx1), math.floor(curx2), -Y, TriY3)
				curx1 -= invslope1
				curx2 -= invslope2
			end
		end
		
		local TriMidX = X1 + (Y2 - Y1) / (Y3 - Y1) * (X3 - X1)
		
		if TriMidX < X2 then
			DrawBottomFlatTriangle(X1, Y1, TriMidX, Y2, X2, Y2)
			DrawTopFlatTriangle(TriMidX, Y2, X2, Y2, X3, Y3)
		else
			DrawBottomFlatTriangle(X1, Y1, X2, Y2, TriMidX, Y2)
			DrawTopFlatTriangle(X2, Y2, TriMidX, Y2, X3, Y3)
		end
	end
	
	CanvasDraw.DrawLineXY(X1, Y1, X2, Y2, Colour)
	CanvasDraw.DrawLineXY(X2, Y2, X3, Y3, Colour)
	CanvasDraw.DrawLineXY(X3, Y3, X1, Y1, Colour)
end


function CanvasDraw.DrawLine(PointA: Vector2, PointB: Vector2, Colour: Color3): {}
	if CheckForCanvas("draw line") then return end
	
	local DrawnPointsArray = {}
	
	local X1 = RoundN(PointA.X)
	local X2 = RoundN(PointB.X)
	local Y1 = RoundN(PointA.Y)
	local Y2 = RoundN(PointB.Y)

	local sx, sy, dx, dy

	if X1 < X2 then
		sx = 1
		dx = X2 - X1
	else
		sx = -1
		dx = X1 - X2
	end

	if Y1 < Y2 then
		sy = 1
		dy = Y2 - Y1
	else
		sy = -1
		dy = Y1 - Y2
	end

	local err, e2 = dx-dy, nil

	while not (X1 == X2 and Y1 == Y2) and X1 < CurrentCanvasResolutionX and Y1 < CurrentCanvasResolutionY and X1 > 0 and Y1 > 0 do
		e2 = err + err
		if e2 > -dy then
			err = err - dy
			X1  = X1 + sx
		end
		if e2 < dx then
			err = err + dx
			Y1 = Y1 + sy
		end
		
		local Point = Vector2.new(X1, Y1)
		CanvasDraw.DrawPixel(Point, Colour)
		TableInsert(DrawnPointsArray, Point)
	end

	return DrawnPointsArray
end

function CanvasDraw.DrawLineXY(X1: number, Y1: number, X2: number, Y2: number, Colour: Color3)
	if CheckForCanvas("draw line (xy)") then return end
	
	local sx, sy, dx, dy

	if X1 < X2 then
		sx = 1
		dx = X2 - X1
	else
		sx = -1
		dx = X1 - X2
	end

	if Y1 < Y2 then
		sy = 1
		dy = Y2 - Y1
	else
		sy = -1
		dy = Y1 - Y2
	end

	local err, e2 = dx-dy, nil

	while not(X1 == X2 and Y1 == Y2) do
		e2 = err + err
		if e2 > -dy then
			err = err - dy
			X1  = X1 + sx
		end
		if e2 < dx then
			err = err + dx
			Y1 = Y1 + sy
		end
		CanvasDraw.SetPixel(X1, Y1, Colour)
	end
end

RunService.Heartbeat:Connect(function()
	if CanvasDraw.AutoUpdate and CurrentCanvas then
		CanvasDraw.Update()
	end
end)

return CanvasDraw