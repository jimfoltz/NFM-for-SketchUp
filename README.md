NFM-for-SketchUp
================

[Need for Madness](http://www.needformadness.com/developer/) is a fun, fast-paced car game written in Java. This SketchUp plugin helps creating vehicles for the game.

Latest Version: **0.5.2**

## Plugin Installation ##

The NFM plugins is a single-file. In a nutshell, you just put the file in SketchUps' Plugins folder.

* Step 1 -
    Download the [nfm-exporter.rb](https://raw.github.com/jimfoltz/NFM-for-SketchUp/master/nfm-exporter.rb) file. (Right-click link, select the *Save  As* option.

* Step 2 - Move or copy the `nfm-exporter.rb` file to your SketchUp/Plugins folder.

    For Google SketchUp 8 on Windows, plugins are located here:

        `C:\Program Files(x86)\Google\Google SketchUp 8\Plugins\`
       
    For Trimble SketchUp 2013 (Make or Pro), plugins 
    
    	`C:\Program Files (x86)\SketchUp\SketchUp 2013\Plugins\`

    (You will need Admin priviledges)    
    
	and on OSX:

        `/Library/Application Support/Google SketchUp 8/SketchUp/Plugins/`

* Step 3 -
    Restart SketchUp. The plugin will be in the **Plugins > Need for Maddness** menu.

## Creating a Model ##

Download this [Sample SketchUp Model](http://sketchup.google.com/3dwarehouse/details?mid=196de521c5d5c3f0b73ce25f042b849a) to get started.

### Things to note: ###

* The car code is generated strictly from Faces - other SketchUp entities such as Groups and Components may be in the model, but are ignored.
* The car is centered (more or less) on the origin.
* The size of the car is appropriate for the default wheels.
* The stats and physics of the car are not included.
* Pay special attention to the names of the Materials in SketchUp - they control things like default colors, headlights, brakelights, glow, and flash. The following special names are supported as SketchUp Material names:
 * 1stColor
 * 2ndColor
 * glass
 * flash
 * glow
 * lightF
 * lightB

Multiple special names can be used for any material, separated by spaces.

## Exporting Car Codes ##

* Select *Show Code* from SketchUp's **Plugins > Need for Madness > Show Code**
menu item.
* Copy and paste the code into the NFM Car Maker code editor.
* Press Save & Preview

If a surface is selected, only the selected surface is displayed in the dialog. Otherwise, the plugin tries to generate the polys for every surface in the model.

