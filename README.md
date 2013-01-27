NFM-for-SketchUp
================

[Need for Madness](http://www.needformadness.com/developer/) is a funny, physics-based car game written in Java. You can create and customize vehicles for the game.

This SketchUp plugin is meant to help creating vehicles.



## Plugin Installation ##


* Step 1 -
    Download the [nfm-exporter.rb](http://dl.dropbox.com/u/2657771/nfm-exporter.rb) file.
* Step 2 -
    Move or copy the `nfm-exporter.rb` file to your SketchUp/Plugins folder.

    For SketchUp 8 on Windows, plugins are located here:

        `C:\Program Files(x86)\Google\Google SketchUp 8\Plugins\`

    and on OSX,

        `/Library/Application Support/Google SketchUp 8/SketchUp/Plugins/`

* Step 3 -
    Restart SketchUp.

## Creating a Model ##

Download this [Sample SketchUp Model](http://sketchup.google.com/3dwarehouse/details?mid=d5387a815f8e5d17990657dd2813bf44) to get started.

Things to note:

* The car code is generated strictly from Faces - other SketchUp entities such as Groups and Components may be in the model, but are ignored.
* The car is centered (more or less) on the origin.
* The size of the car is appropriate for the default wheels.
* The stats and physics of the car are included for covenience. There is no way to edit these from SketchUp. I pasted them from another car file.
* Pay special attention to the names of the Materials in SketchUp - they control things like default colors, headlights, brakelights, glow, and flash. The following special names are supported as SketchUp Material names:
 * 1stColor
 * 2ndColor
 * glass
 * flash
 * glow
 * lightF
 * lightB

Multiple special names can be used for any material, separated by a space.

## Exporting Car Codes ##

* Select *Show Code* from SketchUp's **Plugins > Need for Madness > Show Code**
menu item.
* Copy and paste the code into the NFM Car Maker code editor.
* Press Save & Preview

