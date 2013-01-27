# NFM Exporter for SketchUp
# Jan 2013 jim.foltz@gmail.com

# NFM: Need for Madness (http://www.needformadness.com/)

# Model should consist of Faces only - everthing else is ignored.
#
# Special Material Names

#   If materials are named using the following special names,
#   the named will be included inthe output:
#     * 1stColor
#     * 2ndColor
#     * frontL
#     * backL
#     * glass
#     * flash
#     * glow
#
# Note : Default wheels and physics ar included.
#
require 'sketchup'

module JF
  module NFM
    @release = '2013a'
    @model = Sketchup.active_model

    def self.export
      model    = Sketchup.active_model
      entities = model.active_entities
      faces    = entities.grep(Sketchup::Face)
      # Group Faces by Material
      face_mat = {}
      faces.each do |face|
        if mat = face.material
          matname = face.material.display_name
          face_mat[matname] ||= []
          face_mat[matname] << face
        end
      end
      out = "// NFM Exporter for SketchUp release #{@release}\n"
      out << "// Created on: #{Time.now}\n"
      out << "// Model Title: #{model.title}\n"
      out << "// Model Path: #{model.path}\n\n"

      # Flip each vertex position on export to match NFM axes
      tr = Geom::Transformation.rotation(ORIGIN, X_AXIS, 90.degrees)

      # 1st and 2nd Colors
      first_color = second_color = nil
      model.materials.each do |mat|
        first_color = mat.color if mat.display_name[/1stcolor/i]
        second_color = mat.color if mat.display_name[/2ndcolor/i]
      end
      if first_color
        out << "1stColor(#{first_color.red},#{first_color.green},#{first_color.blue})\n"
      end
      if second_color
        out << "2ndColor(#{second_color.red},#{second_color.green},#{second_color.blue})\n"
      end
      out << "\n"

      faces = entities.grep(Sketchup::Face)
      if faces.size > 210
        UI.messagebox("Model has #{faces.size} faces.")
      end
      #entities.grep(Sketchup::Face).each do |face|
      face_mat.each do |part, faces|
        faces.each do |face|
          o_loop = face.outer_loop
          verts = o_loop.vertices
          out << '<p>' << "\n"
          if mat = face.material
            out << "// #{mat.display_name}\n"
            matname = mat.display_name
            out << 'c('
            out << mat.color.red.to_s << ','
            out << mat.color.green.to_s << ','
            out << mat.color.blue.to_s
            out << ')'
            out << "\n"
            if matname[/glass/i]
              out << "glass()\n"
            end
            if matname[/lightf/i]
              out << "lightF\n"
            end
            if matname[/lightb/i]
              out << "lightB\n"
            end
            if matname[/flash/i]
              #out << "// flash\n"
              out << "gr(-18) // flash\n"
            end
            if matname[/glow/i]
              #out << "// glow\n"
              out << "gr(-10) //glow\n"
            end
          end
          out << "\n"
          verts.each do |vert|
            pos = vert.position
            pos.transform!(tr)
            pos = pos.to_a.map{|e| e.round}
            out << '  p(' << pos.join(',') << ')' 
            out << "\n"
          end
          out << '</p>'
          out << "\n\n"
        end
      end

      # Output default wheels, stats and physics
      out << "// Default Wheels\ngwgr(0)\nrims(140,140,140,18,10)\n"
      out << "w(-45,15,76,11,26,20)\nw(45,15,76,11,-26,20)\n"
      out << "gwgr(0)\nrims(140,140,140,18,10)\n"
      out << "w(-45,15,-76,0,26,20)\nw(45,15,-76,0,-26,20)\n"
      out << "\nstat(128,98,102,109,123)\n"
      out << "\nphysics(50,50,50,50,50,50,50,50,50,50,50,50,50,50,0,4753)\n"

      if @wd and @wd.visible?
        @wd.close
      end

      # Show car code in dialog
      @wd = UI::WebDialog.new('NFM for SketchUp', false, 'JF\\NFM', 500, 500)
      @wd.set_html  <<-EOS
        <html>
        <head>
        <style>#area{height:90%;width:100%;}</style>
        </head>
        <body>
        Select all, Copy.<br>
        <a href="skp:refresh">Refresh</a> |
        <a href="#" onclick="ta.focus();ta.select();">Select</a> 
        <br>
        <textarea id=area name=ta cols=40>#{out}</textarea>
        </body></html>
      EOS
      @wd.add_action_callback('refresh') do |d, a|
        JF::NFM.export
      end
      @wd.show
    end

    def self.import
      tr = Geom::Transformation.rotation(ORIGIN, X_AXIS, -90.degrees)
      file = UI.openpanel
      #file = File.dirname(__FILE__) + '/Simple Car.rad'
      #p file
      in_p = false
      mesh = Geom::PolygonMesh.new
      polygon = []
      IO.foreach(file) do |line|
        #p line
        line.strip!
        next if line.empty?
        if line[/<p>/]
          in_p = true
          mesh = Geom::PolygonMesh.new
          polygon.clear
          next
        end
        if line[/<\/p>/]
          in_p = false
          if not polygon.empty?
            #p polygon
            mesh.add_polygon(polygon)
            #Sketchup.active_model.entities.add_face(polygon)
            Sketchup.active_model.entities.add_faces_from_mesh(mesh, 0)
          end
          next
        end
        if in_p
          if (m = /p\((-?\d+),(-?\d+),(-?\d+)/.match(line))
              #p line
              x = m[1].to_i
              y = m[2].to_i
              z = m[3].to_i
              polygon << [x, y, z]
              #mesh.add_point([x, y, z])
          end
        end
      end
      #p mesh.count_polygons
      #Sketchup.active_model.entities.add_faces_from_mesh(mesh, 0)
      tr = Geom::Transformation.rotation(ORIGIN, X_AXIS, -90.degrees)
      entities = Sketchup.active_model.entities
      entities.transform_entities(tr, entities.to_a)
      Sketchup.active_model.active_view.zoom_extents
    end

    menu = UI.menu('Plugins').add_submenu('Need For Madness')
    menu.add_item('Show Code') { NFM.export }
    #menu.add_item('NFM Import') { NFM.import } 

  end # module NFM
end # module JF
