class 'EyEEditor'

-------------check if user is admin --------------------


-------------------------------------------create window ---------------------------------


function EyEEditor:__init()
	self.active = false 

	self.window = Window.Create()
	self.window:SetSizeRel( Vector2( 0.15, 1.0 ) )
	self.window:SetPositionRel( 
		Vector2( 1.0, 1.0 ) - self.window:GetSizeRel()/2 )
	self.window:SetTitle( "              EyE Editor" )
	self.window:SetVisible( self.active )
	self.window:SendToBack()
    --self window:Text
	
	
	-------------------this is from buymenu-----------pls check
	
	--------------------------------Groupbox For Object Create, Duplicate, Save, Delete Button----------------------------------
	
	self.objbgroupbox = GroupBox.Create(self.window)
	self.objbgroupbox:SizeToContents()
	self.objbgroupbox:SetText("Object")
	--self.objbgroupbox:SetSize(Vector2( self.window:GetSize().x, self.window:GetSize().y/16 ))
	self.objbgroupbox:SetSizeRel(Vector2( 1.0, 0.2 ))
	self.objbgroupbox:SetPositionRel(Vector2( 0.0, 0.6 ))
	
	----------Button Create Single Object-----------------------
	self.buttoncreatesingleobj = Button.Create(self.objbgroupbox)
	self.buttoncreatesingleobj:SetSizeRel( Vector2( 1.0, 0.23  ) )
	self.buttoncreatesingleobj:SetPositionRel(Vector2( 0.0, 0.0 ))
	self.buttoncreatesingleobj:SetText("Create")
	self.buttoncreatesingleobj:Subscribe( "Press", self, self.Vikcreatebutton )   
	
	----------Button Duplicate Single Object----------------
	self.buttonduplicate = Button.Create(self.objbgroupbox)
	self.buttonduplicate:SetSizeRel( Vector2( 1.0, 0.23  ) )
	self.buttonduplicate:SetPositionRel(Vector2( 0.0, 0.23 ))
	self.buttonduplicate:SetText("Duplicate")
	self.buttonduplicate:Subscribe( "Press", self, self.Vikduplicatebutton )
--[[	
	----------Button Save Single Object-----------------------
	self.buttonsavesingleobj = Button.Create(self.objbgroupbox)
	self.buttonsavesingleobj:SetSizeRel( Vector2( 1.0, 0.23  ) )
	self.buttonsavesingleobj:SetPositionRel(Vector2( 0.0, 0.46 ))
	self.buttonsavesingleobj:SetText("Save")
	--self.buttonsavesingleobj:Subscribe( "Press", self, self.Vikdeletebutton )   ------TODO
]]
	----------Button Delete Single Object-----------------------
	self.buttondelete = Button.Create(self.objbgroupbox)
	self.buttondelete:SetSizeRel( Vector2( 1.0, 0.23 ) )
	self.buttondelete:SetPositionRel(Vector2( 0.0, 0.69 ))
	self.buttondelete:SetText("Delete")
	self.buttondelete:Subscribe( "Press", self, self.Vikdeletebutton )
	---------------------------------------------------------------------------------------------------------
	------------------------------------------GroupBox to Delete, Save, Reload All Objects-----------------------------------------------------------------
	self.allobjbgroupbox = GroupBox.Create(self.window)
	self.allobjbgroupbox:SizeToContents()
	self.allobjbgroupbox:SetText("ALL Objects")
	self.allobjbgroupbox:SetSizeRel(Vector2( 1.0, 0.15 ))
	self.allobjbgroupbox:SetPositionRel(Vector2( 0.0, 0.8 ))
	
		---------------Delete_ALL------------------------------------------------------
	self.buttondeleteall = Button.Create(self.allobjbgroupbox)
	self.buttondeleteall:SetSizeRel(Vector2( 1.0, 0.28 ) )
	self.buttondeleteall:SetPositionRel(Vector2( 0, 0 ))
	self.buttondeleteall:SetText("DELETE")
	self.buttondeleteall:Subscribe( "Press", self, self.Vikdeleteallbutton )
	
	-------------------------------------Save To File--------------------------------------
	self.buttonsavetofile = Button.Create(self.allobjbgroupbox)
	self.buttonsavetofile:SetSizeRel(Vector2( 1.0, 0.28 ) )
	self.buttonsavetofile:SetPositionRel(Vector2( 0, 0.3 ))
	self.buttonsavetofile:SetText("Save")
	self.buttonsavetofile:Subscribe( "Press", self, self.Viksavetofilebutton )
	
	-------------------------------------Reload All objects From File--------------------------------------

	self.buttonsavetofile = Button.Create(self.allobjbgroupbox)
	self.buttonsavetofile:SetSizeRel(Vector2( 1.0, 0.28 ) )
	self.buttonsavetofile:SetPositionRel(Vector2( 0, 0.6 ))
	self.buttonsavetofile:SetText("Reload")
	self.buttonsavetofile:Subscribe( "Press", self, self.Vikreloadfromfilebutton )   ---TODO

	------------------------------------------GroupBox For ARRAY Tool ---------------------------------------------
	
	self.arraygroupbox = GroupBox.Create(self.window)
	self.arraygroupbox:SizeToContents()
	self.arraygroupbox:SetSizeRel(Vector2( 0.9, 0.6 ))
	self.arraygroupbox:SetPositionRel(Vector2( 0, 0 ))
	self.arraygroupbox:SetText("Array Tool")
	
	self.arraycreate = Button.Create(self.arraygroupbox)
	self.arraycreate:SetSizeRel( Vector2( 0.4, 0.05 ) )
	self.arraycreate:SetPositionRel(Vector2( 0.3, 0.9 ))
	self.arraycreate:SetText("Create")
	self.arraycreate:Subscribe( "Press", self, self.CreateArray )                          ------------create the array
	--------------------------number of objects -----------------------------------------
	
	----label-----
	self.numberofarrayobjectslabel = Label.Create(self.arraygroupbox)
	self.numberofarrayobjectslabel:SizeToContents()
	self.numberofarrayobjectslabel:SetSizeRel(Vector2( 0.6, 0.05 ))
	self.numberofarrayobjectslabel:SetPositionRel(Vector2( 0, 0.03 ))
	self.numberofarrayobjectslabel:SetText("Number Of Objects:")
	self.numberofarrayobjectslabel:SetTextColor(Color(255, 165, 0))
	
	---------Textbox---------------
	self.numberofarrayobjects = TextBox.Create(self.arraygroupbox)
	self.numberofarrayobjects:SetSizeRel(Vector2( 0.2, 0.05 ))
	self.numberofarrayobjects:SetPositionRel(Vector2( 0.7, 0.02 ))
	self.numberofarrayobjects:SetText("0")
								--------------along axis------------------------
	self.arrayaxisgroupbox = GroupBox.Create(self.arraygroupbox)
	self.arrayaxisgroupbox:SizeToContents()
	self.arrayaxisgroupbox:SetSizeRel(Vector2( 0.9, 0.40 ))
	self.arrayaxisgroupbox:SetPositionRel(Vector2( 0, 0.07 ))
	self.arrayaxisgroupbox:SetText("Along Axis")
	
	----label-----
	self.arrayaxisgroupboxlabelx = Label.Create(self.arrayaxisgroupbox)
	self.arrayaxisgroupboxlabelx:SizeToContents()
	self.arrayaxisgroupboxlabelx:SetSizeRel(Vector2( 0.25, 0.25 ))
	self.arrayaxisgroupboxlabelx:SetPositionRel(Vector2( 0.02, 0.11 ))
	self.arrayaxisgroupboxlabelx:SetText("X:")
	self.arrayaxisgroupboxlabelx:SetTextColor(Color(255, 165, 0))
	
	----label-----
	self.arrayaxisgroupboxlabely = Label.Create(self.arrayaxisgroupbox)
	self.arrayaxisgroupboxlabely:SizeToContents()
	self.arrayaxisgroupboxlabely:SetSizeRel(Vector2( 0.25, 0.25 ))
	self.arrayaxisgroupboxlabely:SetPositionRel(Vector2( 0.02, 0.44 ))
	self.arrayaxisgroupboxlabely:SetText("Y:")
	self.arrayaxisgroupboxlabely:SetTextColor(Color(255, 165, 0))
	
	----label-----
	self.arrayaxisgroupboxlabelz = Label.Create(self.arrayaxisgroupbox)
	self.arrayaxisgroupboxlabelz:SizeToContents()
	self.arrayaxisgroupboxlabelz:SetSizeRel(Vector2( 0.25, 0.25 ))
	self.arrayaxisgroupboxlabelz:SetPositionRel(Vector2( 0.02, 0.75 ))
	self.arrayaxisgroupboxlabelz:SetText("Z:")
	self.arrayaxisgroupboxlabelz:SetTextColor(Color(255, 165, 0))
	
	----------------------Textboxes---------Axis-----Number of objects----------------------------------------
	self.numberofobjectsalongtextx = TextBox.Create(self.arrayaxisgroupbox)
	self.numberofobjectsalongtextx:SizeToContents()
	self.numberofobjectsalongtextx:SetSizeRel(Vector2( 0.25, 0.12 ))
	self.numberofobjectsalongtextx:SetPositionRel(Vector2( 0.25, 0.09 ))
	self.numberofobjectsalongtextx:SetText("0")
	
	self.numberofobjectsalongtexty = TextBox.Create(self.arrayaxisgroupbox)
	self.numberofobjectsalongtexty:SizeToContents()
	self.numberofobjectsalongtexty:SetSizeRel(Vector2( 0.25, 0.12 ))
	self.numberofobjectsalongtexty:SetPositionRel(Vector2( 0.25, 0.41 ))
	self.numberofobjectsalongtexty:SetText("0")
    --self.numberofobjectsalongtexty:Hide()
	
	self.numberofobjectsalongtextz = TextBox.Create(self.arrayaxisgroupbox)
	self.numberofobjectsalongtextz:SizeToContents()
	self.numberofobjectsalongtextz:SetSizeRel(Vector2( 0.25, 0.12 ))
	self.numberofobjectsalongtextz:SetPositionRel(Vector2( 0.25, 0.73 ))
	self.numberofobjectsalongtextz:SetText("0")
	
	
	
	-------------------------------------------------------------------------------------------------
	----------------------------------------------------------------------------------------
	
	--------------------------------------Axis Offset Groupbox----------------------------------------------
	
	self.arrayaxisoffsetgroupbox = GroupBox.Create(self.arrayaxisgroupbox)
	self.arrayaxisoffsetgroupbox:SizeToContents()
	self.arrayaxisoffsetgroupbox:SetSizeRel(Vector2( 0.29, 0.89 ))
	self.arrayaxisoffsetgroupbox:SetPositionRel(Vector2( 0.64, 0.01 ))
	self.arrayaxisoffsetgroupbox:SetText("Offset")
	
	----------------------Textboxes---------Axis-----Offset----------------------------------------
	self.arrayaxisoffsettextx = TextBox.Create(self.arrayaxisoffsetgroupbox)
	self.arrayaxisoffsettextx:SizeToContents()
	self.arrayaxisoffsettextx:SetSizeRel(Vector2( 0.7, 0.12 ))
	self.arrayaxisoffsettextx:SetPositionRel(Vector2( 0, 0.03 ))
	self.arrayaxisoffsettextx:SetText("0")
	
	self.arrayaxisoffsettexty = TextBox.Create(self.arrayaxisoffsetgroupbox)
	self.arrayaxisoffsettexty:SizeToContents()
	self.arrayaxisoffsettexty:SetSizeRel(Vector2( 0.7, 0.12 ))
	self.arrayaxisoffsettexty:SetPositionRel(Vector2( 0, 0.375 ))
	self.arrayaxisoffsettexty:SetText("0")
	
	
	self.arrayaxisoffsettextz = TextBox.Create(self.arrayaxisoffsetgroupbox)
	self.arrayaxisoffsettextz:SizeToContents()
	self.arrayaxisoffsettextz:SetSizeRel(Vector2( 0.7, 0.12 ))
	self.arrayaxisoffsettextz:SetPositionRel(Vector2( 0, 0.75 ))
	self.arrayaxisoffsettextz:SetText("0")
	
	
	
	------------------------------------------------------------------------------------------------------------
	-------------array rotation-groupbox--------------------------------------
	
	self.arrayrotationgroupbox = GroupBox.Create(self.arraygroupbox)
	self.arrayrotationgroupbox:SizeToContents()
	self.arrayrotationgroupbox:SetSizeRel(Vector2( 0.9, 0.40 ))
	self.arrayrotationgroupbox:SetPositionRel(Vector2( 0, 0.49 ))
	self.arrayrotationgroupbox:SetText("Rotation")
	
	-------------------------Labels------------------------------------------------------
	
	----label-----
	self.arrayrotationgroupboxlabelpitch = Label.Create(self.arrayrotationgroupbox)
	self.arrayrotationgroupboxlabelpitch:SizeToContents()
	self.arrayrotationgroupboxlabelpitch:SetSizeRel(Vector2( 0.25, 0.25 ))
	self.arrayrotationgroupboxlabelpitch:SetPositionRel(Vector2( 0.2, 0.1 ))
	self.arrayrotationgroupboxlabelpitch:SetText("Pitch:")
	self.arrayrotationgroupboxlabelpitch:SetTextColor(Color(255, 165, 0))
	
	----label-----
	self.arrayrotationgroupboxlabelroll = Label.Create(self.arrayrotationgroupbox)
	self.arrayrotationgroupboxlabelroll:SizeToContents()
	self.arrayrotationgroupboxlabelroll:SetSizeRel(Vector2( 0.25, 0.25 ))
	self.arrayrotationgroupboxlabelroll:SetPositionRel(Vector2( 0.2, 0.41 ))
	self.arrayrotationgroupboxlabelroll:SetText("Roll:")
	self.arrayrotationgroupboxlabelroll:SetTextColor(Color(255, 165, 0))
	
	----label-----
	self.arrayrotationgroupboxlabelyaw = Label.Create(self.arrayrotationgroupbox)
	self.arrayrotationgroupboxlabelyaw:SizeToContents()
	self.arrayrotationgroupboxlabelyaw:SetSizeRel(Vector2( 0.25, 0.25 ))
	self.arrayrotationgroupboxlabelyaw:SetPositionRel(Vector2( 0.2, 0.76 ))
	self.arrayrotationgroupboxlabelyaw:SetText("Yaw:")
	self.arrayrotationgroupboxlabelyaw:SetTextColor(Color(255, 165, 0))
	
	
	
	-------------------------------------------------------------------------------------
	
	self.arrayrotationoffsetgroupbox = GroupBox.Create(self.arrayrotationgroupbox)
	self.arrayrotationoffsetgroupbox:SizeToContents()
	self.arrayrotationoffsetgroupbox:SetSizeRel(Vector2( 0.29, 0.89 ))
	self.arrayrotationoffsetgroupbox:SetPositionRel(Vector2( 0.64, 0.01 ))
	self.arrayrotationoffsetgroupbox:SetText("Offset")
	
	
	----------------------Textboxes---------Axis-----Offset----------------------------------------
	self.arrayrotationoffsettextpitch = TextBox.Create(self.arrayrotationoffsetgroupbox)
	self.arrayrotationoffsettextpitch:SizeToContents()
	self.arrayrotationoffsettextpitch:SetSizeRel(Vector2( 0.7, 0.12 ))
	self.arrayrotationoffsettextpitch:SetPositionRel(Vector2( 0, 0.03 ))
	self.arrayrotationoffsettextpitch:SetText("0")
	
	self.arrayrotationoffsettextroll = TextBox.Create(self.arrayrotationoffsetgroupbox)
	self.arrayrotationoffsettextroll:SizeToContents()
	self.arrayrotationoffsettextroll:SetSizeRel(Vector2( 0.7, 0.12 ))
	self.arrayrotationoffsettextroll:SetPositionRel(Vector2( 0, 0.375 ))
	self.arrayrotationoffsettextroll:SetText("0")
	
	
	self.arrayrotationoffsettextyaw = TextBox.Create(self.arrayrotationoffsetgroupbox)
	self.arrayrotationoffsettextyaw:SizeToContents()
	self.arrayrotationoffsettextyaw:SetSizeRel(Vector2( 0.7, 0.12 ))
	self.arrayrotationoffsettextyaw:SetPositionRel(Vector2( 0, 0.75 ))
	self.arrayrotationoffsettextyaw:SetText("0")
	
	
	
	
	
	
	
	--------------------------------------------------------------------------------------------------------------
	-----------------------------------------Vertical Window------------------------------------------------------
	--------------------------------------------------------------------------------------------------------------
	
	
	self.window1 = Window.Create()
	self.window1:SetSizeRel( Vector2( 0.85, 0.16 ) )
	self.window1:SetPositionRel( 
		Vector2( 0.0, 0.0 ) - self.window:GetSizeRel()/2 )
	self.window1:SetTitle( "     EyE Editor" )
	self.window1:SetVisible( self.active )
	self.window1:SendToBack()
	
	---------------------------Groupbox for movespeed buttons---------------------------------
	self.movespeedgroupbox = GroupBox.Create(self.window1)
	self.movespeedgroupbox:SizeToContents()
	self.movespeedgroupbox:SetSizeRel(Vector2( 0.1, 0.3 ))
	self.movespeedgroupbox:SetPositionRel(Vector2( 0, 0 ))
	self.movespeedgroupbox:SetText("Move Speed")
	
	---------------------------Button Movespeed Increase------------------------------
	self.buttonincreasespeed = Button.Create(self.movespeedgroupbox)
	self.buttonincreasespeed:SetSizeRel( Vector2( 0.4, 0.75 ) )
	self.buttonincreasespeed:SetPositionRel(Vector2( 0.5, 0 ))
	self.buttonincreasespeed:SetText("+")
	self.buttonincreasespeed:Subscribe( "Press", self, self.Vikincreasebutton )
	--------------------------Button Movespeed Decrease------------------------------------------------
	self.buttondecreasespeed = Button.Create(self.movespeedgroupbox)
	self.buttondecreasespeed:SetSizeRel( Vector2( 0.4, 0.75 ) )
	self.buttondecreasespeed:SetPositionRel(Vector2( 0.0, 0.0 ))
	self.buttondecreasespeed:SetText("-")
	self.buttondecreasespeed:Subscribe( "Press", self, self.Vikdecreasebutton )
	---------------------------------------------------------------------------------------------
	
	---------------------------Groupbox for rotationspeed buttons---------------------------------
	self.rotationspeedgroupbox = GroupBox.Create(self.window1)
	self.rotationspeedgroupbox:SizeToContents()
	self.rotationspeedgroupbox:SetSizeRel(Vector2( 0.1, 0.3 ))
	self.rotationspeedgroupbox:SetPositionRel(Vector2( 0, 0.35 ))
	self.rotationspeedgroupbox:SetText("Rotation Speed")
	---------------------------Button Rotationspeed Increase------------------------------
	self.buttonincreasespeedr = Button.Create(self.rotationspeedgroupbox)
	self.buttonincreasespeedr:SetSizeRel( Vector2( 0.4, 0.75 ) )
	self.buttonincreasespeedr:SetPositionRel(Vector2( 0.5, 0 ))
	self.buttonincreasespeedr:SetText("+")
	self.buttonincreasespeedr:Subscribe( "Press", self, self.Vikincreaserbutton )
	--------------------------Button Rotationspeed Decrease------------------------------------------------
	self.buttondecreasespeed = Button.Create(self.rotationspeedgroupbox)
	self.buttondecreasespeed:SetSizeRel( Vector2( 0.4, 0.75 ) )
	self.buttondecreasespeed:SetPositionRel(Vector2( 0.0, 0.0 ))
	self.buttondecreasespeed:SetText("-")
	self.buttondecreasespeed:Subscribe( "Press", self, self.Vikdecreaserbutton )
	-------------------------------------------------------------------------------------------------
	
	---------------------------Groupbox for Object Movement buttons---------------------------------
	------------------------------------------------------------------------------------------------
	self.objectmovementgroupbox = GroupBox.Create(self.window1)
	self.objectmovementgroupbox:SizeToContents()
	self.objectmovementgroupbox:SetSizeRel(Vector2( 0.145, 0.72 ))
	self.objectmovementgroupbox:SetPositionRel(Vector2( 0.11, 0.0 ))
	self.objectmovementgroupbox:SetText("Object Movement")
	
	---------------------------Button Objectmovement UP------------------------------
	self.buttonmoveobjectup = Button.Create(self.objectmovementgroupbox)
	self.buttonmoveobjectup:SetSizeRel( Vector2( 0.29, 0.4 ) )
	self.buttonmoveobjectup:SetPositionRel(Vector2( 0.0, 0.0 ))
	self.buttonmoveobjectup:SetText("UP")
	self.buttonmoveobjectup:Subscribe( "Press", self, self.VikmoveobjectUpbutton )     
	
	---------------------------Button Objectmovement Left------------------------------
	self.buttonmoveobjectleft = Button.Create(self.objectmovementgroupbox)
	self.buttonmoveobjectleft:SetSizeRel( Vector2( 0.29, 0.4 ) )
	self.buttonmoveobjectleft:SetPositionRel(Vector2( 0.0, 0.45 ))
	self.buttonmoveobjectleft:SetText("Left")
	self.buttonmoveobjectleft:Subscribe( "Press", self, self.VikmoveobjectLeftbutton )
	
	---------------------------Button Objectmovement Forward------------------------------
	self.buttonmoveobjectforward = Button.Create(self.objectmovementgroupbox)
	self.buttonmoveobjectforward:SetSizeRel( Vector2( 0.29, 0.4 ) )
	self.buttonmoveobjectforward:SetPositionRel(Vector2( 0.33, 0.0 ))
	self.buttonmoveobjectforward:SetText("Forward")
	self.buttonmoveobjectforward:Subscribe( "Press", self, self.VikmoveobjectForwardbutton )     
	
	---------------------------Button Objectmovement Back------------------------------
	self.buttonmoveobjectback = Button.Create(self.objectmovementgroupbox)
	self.buttonmoveobjectback:SetSizeRel( Vector2( 0.29, 0.4 ) )
	self.buttonmoveobjectback:SetPositionRel(Vector2( 0.33, 0.45 ))
	self.buttonmoveobjectback:SetText("Back")
	self.buttonmoveobjectback:Subscribe( "Press", self, self.VikmoveobjectBackbutton )
	
	---------------------------Button Objectmovement Down------------------------------
	self.buttonmoveobjectdown = Button.Create(self.objectmovementgroupbox)
	self.buttonmoveobjectdown:SetSizeRel( Vector2( 0.29, 0.4 ) )
	self.buttonmoveobjectdown:SetPositionRel(Vector2( 0.66, 0.0 ))
	self.buttonmoveobjectdown:SetText("Down")
	self.buttonmoveobjectdown:Subscribe( "Press", self, self.VikmoveobjectDownbutton )     
	
	---------------------------Button Objectmovement Right------------------------------
	self.buttonmoveobjectright = Button.Create(self.objectmovementgroupbox)
	self.buttonmoveobjectright:SetSizeRel( Vector2( 0.29, 0.4 ) )
	self.buttonmoveobjectright:SetPositionRel(Vector2( 0.66, 0.45 ))
	self.buttonmoveobjectright:SetText("Right")
	self.buttonmoveobjectright:Subscribe( "Press", self, self.VikmoveobjectRightbutton )
	
	
	---------------------------Groupbox for Object Rotation buttons---------------------------------
	------------------------------------------------------------------------------------------------
	self.objectrotationgroupbox = GroupBox.Create(self.window1)
	self.objectrotationgroupbox:SizeToContents()
	self.objectrotationgroupbox:SetSizeRel(Vector2( 0.15, 0.72 ))
	self.objectrotationgroupbox:SetPositionRel(Vector2( 0.26, 0.0 ))
	self.objectrotationgroupbox:SetText("Object Rotation")
	
	---------------------------Button ObjectRotation Pitch Pos------------------------------
	self.buttonrotateobjectpitchpos = Button.Create(self.objectrotationgroupbox)
	self.buttonrotateobjectpitchpos:SetSizeRel( Vector2( 0.29, 0.4 ) )
	self.buttonrotateobjectpitchpos:SetPositionRel(Vector2( 0.0, 0.0 ))
	self.buttonrotateobjectpitchpos:SetText("+\nPitch")
	self.buttonrotateobjectpitchpos:Subscribe( "Press", self, self.VikObjectRotPitchbutton )     
	
	---------------------------Button ObjectRotation Pitch Neg------------------------------
	self.buttonrotateobjectpitchneg = Button.Create(self.objectrotationgroupbox)
	self.buttonrotateobjectpitchneg:SetSizeRel( Vector2( 0.29, 0.4 ) )
	self.buttonrotateobjectpitchneg:SetPositionRel(Vector2( 0.0, 0.45 ))
	self.buttonrotateobjectpitchneg:SetText("-\nPitch")
	self.buttonrotateobjectpitchneg:Subscribe( "Press", self, self.VikObjectRotPitchnbutton )
	
	---------------------------ObjectRotation Roll Pos------------------------------
	self.buttonrotateobjectrollpos = Button.Create(self.objectrotationgroupbox)
	self.buttonrotateobjectrollpos:SetSizeRel( Vector2( 0.29, 0.4 ) )
	self.buttonrotateobjectrollpos:SetPositionRel(Vector2( 0.33, 0.0 ))
	self.buttonrotateobjectrollpos:SetText("+\nRoll")
	self.buttonrotateobjectrollpos:Subscribe( "Press", self, self.VikObjectRotRollbutton )     
	
	---------------------------ObjectRotation Roll Neg------------------------------
	self.buttonrotateobjectrollneg = Button.Create(self.objectrotationgroupbox)
	self.buttonrotateobjectrollneg:SetSizeRel( Vector2( 0.29, 0.4 ) )
	self.buttonrotateobjectrollneg:SetPositionRel(Vector2( 0.33, 0.45 ))
	self.buttonrotateobjectrollneg:SetText("-\nRoll")
	self.buttonrotateobjectrollneg:Subscribe( "Press", self, self.VikObjectRotRollnbutton )
	
	---------------------------ObjectRotation Yaw Pos------------------------------
	self.buttonrotateobjectyawpos = Button.Create(self.objectrotationgroupbox)
	self.buttonrotateobjectyawpos:SetSizeRel( Vector2( 0.29, 0.4 ) )
	self.buttonrotateobjectyawpos:SetPositionRel(Vector2( 0.66, 0.0 ))
	self.buttonrotateobjectyawpos:SetText("+\nYaw")
	self.buttonrotateobjectyawpos:Subscribe( "Press", self, self.VikObjectRotYawbutton )     
	
	---------------------------ObjectRotation Yaw Neg------------------------------
	self.buttonrotateobjectyawneg = Button.Create(self.objectrotationgroupbox)
	self.buttonrotateobjectyawneg:SetSizeRel( Vector2( 0.29, 0.4 ) )
	self.buttonrotateobjectyawneg:SetPositionRel(Vector2( 0.66, 0.45 ))
	self.buttonrotateobjectyawneg:SetText("-\nYaw")
	self.buttonrotateobjectyawneg:Subscribe( "Press", self, self.VikObjectRotYawnbutton )
	
	
	--[[
	---------------------------Stats GroupBox---------------------------------------------------
	-----------------------------------------------------------------------------------------------
	self.statsgroupbox = GroupBox.Create(self.window1)
	self.statsgroupbox:SizeToContents()
	self.statsgroupbox:SetSizeRel(Vector2( 0.39, 0.72 ))
	self.statsgroupbox:SetPositionRel(Vector2( 0.60, 0.0 ))
	self.statsgroupbox:SetText("Stats")
	
	self.modelnametextbox = TextBox.Create(self.statsgroupbox)
	self.modelnametextbox:SetSizeRel(Vector2( 0.5, 0.4 ))
	self.modelnametextbox:SetPositionRel(Vector2( 0.0, 0.0 ))
	self.modelnametextbox:SetText("some model name in here please")

	self.collisionnametextbox = TextBox.Create(self.statsgroupbox)
	self.collisionnametextbox:SetSizeRel(Vector2( 0.5, 0.4 ))
	self.collisionnametextbox:SetPositionRel(Vector2( 0.0, 0.45 ))
	self.collisionnametextbox:SetText("some Collision name in hereplease")

	]]

	-------------------------------------------------------------------------------------------------
	Network:Subscribe( "Stats", self, self.UpdateStats)
	Events:Subscribe( "KeyUp", self,
		self.KeyUp )

	Events:Subscribe( "LocalPlayerInput", self,
		self.LocalPlayerInput )

	self.window:Subscribe( "WindowClosed", self, 
		self.WindowClosed )


	-----------------------------Array Logic-------------------------------------------------------------------
	------variables-----
	self.NumberOfObjects 	= 0  ---master
	
	self.NumberOfObjX 		= 0
	self.NumberOfObjY 		= 0
	self.NumberOfObjZ		= 0
	
	self.OffsetX = 0
	self.OffestY = 0
	self.OffsetZ = 0
	
	self.OffsetPitch = 0
	self.OffsetRoll  = 0
	self.OffsetYaw   = 0 

end

function EyEEditor:CreateArray()

local args = {}																---create arguments table and populate it

args.NumberOfObjects = self.numberofarrayobjects:GetText()

args.NumberOfObjX 	 = self.numberofobjectsalongtextx:GetText()
args.NumberOfObjY 	 = self.numberofobjectsalongtexty:GetText()
args.NumberOfObjZ	 = self.numberofobjectsalongtextz:GetText()

args.OffsetX		 = self.arrayaxisoffsettextx:GetText()
args.OffsetY 		 = self.arrayaxisoffsettexty:GetText()
args.OffsetZ		 = self.arrayaxisoffsettextz:GetText()

args.OffsetPitch 	 = self.arrayrotationoffsettextpitch:GetText()
args.OffsetRoll  	 = self.arrayrotationoffsettextroll:GetText()
args.OffsetYaw   	 = self.arrayrotationoffsettextyaw:GetText()

--[[
if args.NumberOfObjects  == nil then  args.NumberOfObjects = 0 end

if args.NumberOfObjX == nil then  args.NumberOfObjX = 1 end

if args.NumberOfObjY == nil then  args.NumberOfObjY = 0 end

if args.NumberOfObjZ == nil then  args.NumberOfObjZ = 1 end

if args.OffsetX      == nil then args.OffsetX  = 1 end
if args.OffsetY      == nil then args.OffsetY  = 1 end
if args.OffsetZ      == nil then args.OffsetZ  = 1 end

if args.OffsetPitch ==  nil then args.OffsetPitch  = 0 end
if args.OffsetRoll  ==  nil then  args.OffsetRoll   = 0 end
if args.OffsetYaw   ==  nil then  args.OffsetYaw = 0 end
]]

---random----
args.randposx = 0
args.randposy = 0
args.randposz = 0

args.randrotp = 0
args.randrotr = 0
args.randroty = 0

if args.OffsetX == "r" then args.randposx = 1 end
if args.OffsetY == "r" then args.randposy = 1 end
if args.OffsetZ == "r" then args.randposz = 1 end

if args.OffsetPitch == "r" then args.randrotp = 1 end
if args.OffsetRoll == "r" then args.randrotr = 1 end
if args.OffsetYaw == "r" then args.randroty = 1 end


Network:Send( "SpawnArray", args )
 ----send off variables to spawner------------------
  
end



----------------------------------------------------------------------------------------------------------------------------
function EyEEditor:UpdateStats(args, player)

--local entstr = string.format(" %s", args.model,"," )
	--player:SendChatMessage( "Object" ..entstr.. "Duplicated" , Color( 250, 250, 250, 72 ) )
local entstr2 = tostring(args.model)

self.modelnametextbox:SetText(entstr2)


end

function EyEEditor:GetActive()
	return self.active
end

function EyEEditor:SetActive( state )
	self.active = state
	self.window:SetVisible( self.active )
	self.window1:SetVisible( self.active )
	Mouse:SetVisible( self.active )
end

function EyEEditor:KeyUp( args )
	if args.key == string.byte('L')  then
		self:SetActive( not self:GetActive() )
	end
end

function EyEEditor:LocalPlayerInput( args )
	if self:GetActive() and Game:GetState() == GUIState.Game then
		return false
	end
end

function EyEEditor:WindowClosed( args )
	self:SetActive( false )
end
------------------------Button Functions--------------------------------

function EyEEditor:Vikreloadfromfilebutton( args )
	Network:Send( "ReloadFromFile", mplayer3 )
end


function EyEEditor:Vikcreatebutton( args )
	Network:Send( "buymodel", mplayer3 )
end

function EyEEditor:Vikdeletebutton( args )
	Network:Send( "RemoveEnt", mplayer3 )
end

function EyEEditor:Vikduplicatebutton( args )
	Network:Send( "DuplicateEntGui", mplayer3 )
end

function EyEEditor:Vikdeleteallbutton( args )
	Network:Send( "RemoveAll", mplayer3 )
end

function EyEEditor:Viksavetofilebutton( args )
	Network:Send( "SaveToFile", mplayer3 )
end

function EyEEditor:Vikincreasebutton( args )
	Network:Send( "Increase", mplayer3 )
end

function EyEEditor:Vikdecreasebutton( args )
	Network:Send( "Decrease", mplayer3 )
end

function EyEEditor:Vikincreaserbutton( args )
	Network:Send( "Increaser", mplayer3 )
end

function EyEEditor:Vikdecreaserbutton( args )
	Network:Send( "Decreaser", mplayer3 )
end
--------------------------------Movement----------------------------------------------
function EyEEditor:VikmoveobjectUpbutton( args )
	Network:Send( "ObjectUp", mplayer3 )
end



	





function EyEEditor:VikmoveobjectLeftbutton( args )
	local args = {}
		args.angle = Camera:GetAngle()
	Network:Send( "ObjectRight", args )
end
function EyEEditor:VikmoveobjectForwardbutton( args )
	local args = {}
		args.angle = Camera:GetAngle()
	Network:Send( "ObjectForward", args )
end
function EyEEditor:VikmoveobjectBackbutton( args )
	local args = {}
		args.angle = Camera:GetAngle()
	Network:Send( "ObjectBackward", args )
end
function EyEEditor:VikmoveobjectDownbutton( args )
	Network:Send( "ObjectDown", mplayer3 )
end
function EyEEditor:VikmoveobjectRightbutton( args )
	local args = {}
		args.angle = Camera:GetAngle()
	Network:Send( "ObjectLeft", args )
end
-------------------------------Rotation buttons------------------------------------------------------
function EyEEditor:VikObjectRotYawnbutton( args )
	Network:Send( "ObjectRotYawn", mplayer3 )
end
function EyEEditor:VikObjectRotYawbutton( args )
	Network:Send( "ObjectRotYaw", mplayer3 )
end
function EyEEditor:VikObjectRotPitchnbutton( args )
	Network:Send( "ObjectRotPitchn", mplayer3 )
end
function EyEEditor:VikObjectRotPitchbutton( args )
	Network:Send( "ObjectRotPitch", mplayer3 )
end
function EyEEditor:VikObjectRotRollnbutton( args )
	Network:Send( "ObjectRotRolln", mplayer3 )
end
function EyEEditor:VikObjectRotRollbutton( args )
	Network:Send( "ObjectRotRoll", mplayer3 )
end

--Foo = function(args)
--	local message = "Mouse position: "..args.position
--	Chat:Print(message, Color(255, 255, 255))
--end
 
--Events:Subscribe("MouseMove", Foo)

-------------------------------------------------------------------------------------------------------

eyeeditor = EyEEditor()



----------------------------Movespeed Adjustments--------------------------
VikIncrease = function (args)
		
    if Key:IsDown(162) then 
      if args.delta == 1 then 
	  Network:Send( "Increaser", mplayer3 )
    end
	end
		
		if not Key:IsDown(162) then
		if args.delta == 1 then
		Network:Send( "Increase", mplayer3 )
		--Network:Send( "Increaser", mplayer3 )
		end
		end
		end
		

VikDecrease = function (args)
		
		if Key:IsDown(162) then 
      if args.delta == -1 then 
	  Network:Send( "Decreaser", mplayer3 )
    end
	end
		
		if not Key:IsDown(162) then
		if args.delta == -1 then
		Network:Send( "Decrease", mplayer3 )
		end
		end
		end
		
VikPickSet = function (args)
		
		
			if args.button == 1 then
      if Key:IsDown(160)  then 
	  Network:Send( "Addtoset", mplayer3 )
    end
	end
		
		if  Key:IsDown(160) then
		if args.button == 2 then
		Network:Send( "Clearset", mplayer3 )
		end
		end
		end

VikDupref = function (args)
		
		if args.button == 1 and
		GUIState ~= 2 then
		Network:Send( "Savedupref", mplayer3 )
		--end
		end	
		end
		
VikDuplicateEnt = function (args)
		
		if not Key:IsDown(160)  then
		if args.button == 2 then
		--if LocalPlayer:GetState() == PlayerState.OnFoot then
		Network:Send( "DuplicateEnt", mplayer3 )
		--end
		end
		end	
		end
		


VikRemoveEntf = function (args)
		
		if args.button == 3 then
		--if LocalPlayer:GetState() == PlayerState.OnFoot then
		Network:Send( "RemoveEnt", mplayer3 )
		--end
		end	
		end
-------------------------------Object Movement Keys------------------------------
VikMoveStaticObjectUp = function (args)
		
		if not Key:IsDown(160) then
		if args.key == string.byte('Y') then
		Network:Send( "ObjectUp", mplayer3 )
		--Network:Send( "Increaser", mplayer3 )
		end
		end
		
	  if Key:IsDown(160) then 
      if args.key == string.byte('Y') then 
	  Network:Send( "ObjectsetUp", mplayer3 )
    end
	end
	end
		

VikMoveStaticObjectDown = function (args)
		if not Key:IsDown(160) then
		if args.key == string.byte('I') then
		Network:Send( "ObjectDown", mplayer3 )
		end
		end 
		if Key:IsDown(160) then 
      if args.key == string.byte('I') then 
	  Network:Send( "ObjectsetDown", mplayer3 )
    end
	end
	end
	
VikMoveStaticObjectLeft = function (args)
		
		if not Key:IsDown(160) then
		if args.key == string.byte('K') then
		local args = {}
		args.angle = Camera:GetAngle()
		Network:Send( "ObjectLeft", args )
		end
		end 
		if Key:IsDown(160) then 
      if args.key == string.byte('K') then 
	  local args = {}
	  args.angle = Camera:GetAngle()
	  Network:Send( "ObjectsetLeft", args )
    end
	end
	end
		
		
VikMoveStaticObjectRight = function (args)

		if not Key:IsDown(160) then
		if args.key == string.byte('H') then
		local args = {}
		args.angle = Camera:GetAngle()
		Network:Send( "ObjectRight", args )
		end
		end 
		if Key:IsDown(160) then 
      if args.key == string.byte('H') then 
	  local args = {}
	  args.angle = Camera:GetAngle()
	  Network:Send( "ObjectsetRight", args )
    end
	end
	end	

VikMoveStaticObjectForward = function (args)
		if not Key:IsDown(160) then
		if args.key == string.byte('U') then
		local args = {}
		args.angle = Camera:GetAngle()
		Network:Send( "ObjectForward", args )
		end
		end 
		if Key:IsDown(160) then 
      if args.key == string.byte('U') then 
	  local args = {}
	  args.angle = Camera:GetAngle()
	  Network:Send( "ObjectsetForward", args )
    end
	end
	end	
		

VikMoveStaticObjectBackward = function (args)
		if not Key:IsDown(160) then
		if args.key == string.byte('J') then
		local args = {}
		args.angle = Camera:GetAngle()
		Network:Send( "ObjectBackward", args )
		end
		end 
		if Key:IsDown(160) then 
      if args.key == string.byte('J') then 
	  local args = {}
	  args.angle = Camera:GetAngle()
	  Network:Send( "ObjectsetBackward", args )
    end
	end
	end	
		





-----------------------------------Rotations---------------------------------------
VikRotateStaticObjectRight = function (args)
		
		if Key:IsDown(100) then
		
		Network:Send( "ObjectRotYawn", mplayer3 )
		end
		end 				

VikRotateStaticObjectLeft = function (args)
		
		if Key:IsDown(102) then
		
		Network:Send( "ObjectRotYaw", mplayer3 )
		end
		end 						

VikRotateStaticObjectUp = function (args)
		
		if Key:IsDown(97) then
		
		Network:Send( "ObjectRotPitchn", mplayer3 )
		end
		end 

VikRotateStaticObjectDown = function (args)
		
		if Key:IsDown(99) then
		
		Network:Send( "ObjectRotPitch", mplayer3 )
		end
		end 

VikRotateStaticObjectRoll = function (args)
		
		if Key:IsDown(104) then
		
		Network:Send( "ObjectRotRolln", mplayer3 )
		end
		end 		

VikRotateStaticObjectRolln = function (args)
		
		if Key:IsDown(98) then
		
		Network:Send( "ObjectRotRoll", mplayer3 )
		end
		end 	

-------------------------------Save Car Coordinates to Cars.txt file------------
VikSaveCarCoords = function (args)
		
		--if args.key == string.byte('0') then
		
		--Network:Send( "SaveCarCoords", mplayer3 )
		--end
		end 			
local first 
local second 
function aimdistance(args)





if Key:IsDown(161) then
		if args.button == 1 then
		f1 = LocalPlayer:GetAimTarget()
	    first = f1.position
	
		end
		end 
		if Key:IsDown(161) then 
      if args.button == 2 then
	  f2 = LocalPlayer:GetAimTarget()
	    second = f2.position  
		local resx = first.x - second.x
		local resy = first.y - second.y
		local resz = first.z - second.z
Chat:Print("Distance is on X "..tostring(resx), Color(0, 0, 255,32))
Chat:Print("Distance is on Y "..tostring(resy), Color(0, 0, 255,32))
Chat:Print("Distance is on Z "..tostring(resz), Color(0, 0, 255,32))
end

end 

end
choosemode = false
rendrobjects = {} -- key is numindex, value is object
currentselection = 0 -- 1 - 10
currentvector = nil
-------------------------
function BetterSelect(args)
	if args.key == 38 then -- up / activate-deactivate
		choosemode = not choosemode
		currentselection = 1
		local plypos = LocalPlayer:GetPosition()
		local counter = 1
		for obj in Client:GetStaticObjects() do
			if plypos:Distance(obj:GetPosition()) <= 35 then
				rendrobjects[counter] = obj
				counter = counter + 1
			end
		end
		currentvector = rendrobjects[currentselection]
	elseif args.key == 39 then -- right
		if choosemode ~= true then return end
		local oldselection = currentvector
		if currentselection < 15 then currentselection = currentselection + 1 end
		currentvector = rendrobjects[currentselection]
		if currentvector == nil then
			currentvector = oldselection
			currentselection = currentselection - 1
		end
	elseif args.key == 40 then -- down / execute
		if choosemode ~= true then return end
		if IsValid(currentvector) then
			Network:Send("ChangeEnt", {myobject = currentvector})
			currentvector = nil
		end
		for key, value in pairs(rendrobjects) do rendrobjects[key] = nil end
	elseif args.key == 37 then -- left
		if choosemode ~= true then return end
		local oldselection = currentvector
		if currentselection > 1 then currentselection = currentselection - 1 end
		currentvector = rendrobjects[currentselection]
		if currentvector == nil then
			currentvector = oldselection
			currentselection = currentselection + 1
		end
	end
end
Events:Subscribe("KeyDown", BetterSelect)
--
function BetterSelectRendr()
if choosemode == false then return end
if currentvector then
	if not IsValid(currentvector) then return end
	local pos = currentvector:GetPosition()
	local transform = Transform3()
	transform:Translate(Vector3(pos.x, pos.y, pos.z))
	transform:Rotate(Angle(0.5 * math.pi, 0, 0))
	Render:SetTransform(transform)
	Render:FillCircle(Vector3.Zero, 1, Color(0, 255, 0, 200))
	Render:ResetTransform()
end

end
Events:Subscribe("Render", BetterSelectRendr)		

Events:Subscribe("MouseDown", aimdistance)
Events:Subscribe("KeyDown", aimdistance)
		
-------------------Value Changing functions------------

--Events:Subscribe("KeyDown", VikSwitch)
Events:Subscribe("MouseScroll", VikIncrease)
Events:Subscribe("MouseScroll", VikDecrease)
-----------------Object Movement-----------------------
Events:Subscribe("KeyDown", VikMoveStaticObjectUp)
Events:Subscribe("KeyDown", VikMoveStaticObjectDown)
Events:Subscribe("KeyDown", VikMoveStaticObjectLeft)
Events:Subscribe("KeyDown", VikMoveStaticObjectRight)
Events:Subscribe("KeyDown", VikMoveStaticObjectForward)
Events:Subscribe("KeyDown", VikMoveStaticObjectBackward)

-----------------Rotations-----------------------------
Events:Subscribe("KeyDown", VikRotateStaticObjectRight)
Events:Subscribe("KeyDown", VikRotateStaticObjectLeft)
Events:Subscribe("KeyDown", VikRotateStaticObjectUp)
Events:Subscribe("KeyDown", VikRotateStaticObjectDown)
Events:Subscribe("KeyDown", VikRotateStaticObjectRoll)
Events:Subscribe("KeyDown", VikRotateStaticObjectRolln)
------------------Save dupref-------------------------

Events:Subscribe("MouseDown", VikPickSet)
Events:Subscribe("KeyDown", VikPickSet)
Events:Subscribe("MouseDown", VikDupref)
Events:Subscribe("MouseDown", VikRemoveEntf)
Events:Subscribe("MouseDown", VikDuplicateEnt)
Events:Subscribe("KeyDown", VikDuplicateEnt)


Events:Subscribe("KeyDown", VikSaveCarCoords)
-------------------Old stuff----------------------------

--Events:Subscribe("KeyDown", KeyUp)
--Events:Subscribe("KeyDown", Keydown)

--

function AngleRender()
	--print("ie")
	for obj in Client:GetStaticObjects() do
		--print("enterino")
		Render:DrawText(Render:WorldToScreen(obj:GetPosition()), tostring(obj:GetAngle()), Color(170, 193, 213, 200), TextSize.Default * 1.25)
	end
end
Events:Subscribe("Render", AngleRender)