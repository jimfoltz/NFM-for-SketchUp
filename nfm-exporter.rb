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

    def self.export_old
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
          while verts[0] == verts[-1]
            verts.pop
          end
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

    def self.export
      model    = Sketchup.active_model
      entities = model.active_entities
      tr = Geom::Transformation.rotation(ORIGIN, X_AXIS, 90.degrees)
      out = ''
      #out = "// NFM Exporter for SketchUp release #{@release}\n"
      #out << "// Created on: #{Time.now}\n"
      #out << "// Model Title: #{model.title}\n"
      #out << "// Model Path: #{model.path}\n\n"

      # Flip each vertex position on export to match NFM axes

      out << "\n"

      surfaces = all_surfaces
      if surfaces.size > 210
        UI.messagebox("Model has #{surfaces.size} surfaces.")
      end
      surfaces.each do |surface|
        if surface.length < 1
          model.selection.clear
          model.selection.add surface
          fail surface.inspect
        end
        outer_edges = surface_outer_edges(surface)
        sorted_edges = sort_edges(outer_edges)
        begin
          sorted_verts = sort_vertices(sorted_edges)
        rescue
          model.selection.clear
          model.selection.add(outer_edges)
          raise
        end
        out << '<p>' << "\n"
        do_color(surface, out)
        while sorted_verts[0] == sorted_verts[-1]
        sorted_verts.pop
        end
        sorted_verts.each do |vert|
          pos = vert.position
          pos.transform!(tr)
          pos = pos.to_a.map{|e| e.round}
          out << 'p(' << pos.join(',') << ')' 
          out << "\n"
        end
        out << '</p>'
        out << "\n"
        out << "\n"
      end

      # Output default wheels, stats and physics
      #out << "// Default Wheels\ngwgr(0)\nrims(140,140,140,18,10)\n"
      #out << "w(-45,15,76,11,26,20)\nw(45,15,76,11,-26,20)\n"
      #out << "gwgr(0)\nrims(140,140,140,18,10)\n"
      #out << "w(-45,15,-76,0,26,20)\nw(45,15,-76,0,-26,20)\n"
      #out << "\nstat(128,98,102,109,123)\n"
      #out << "\nphysics(50,50,50,50,50,50,50,50,50,50,50,50,50,50,0,4753)\n"

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
    end # def export2

    def self.do_color(surface, out)
      face = surface[0]
      #out << "c(255,255,255)\n"
      if mat = face.material
        color = mat.color
        matname = mat.display_name
      else
        color = Sketchup.active_model.rendering_options['FaceFrontColor']
        matname = 'Default Color'
      end
        out << "// #{matname}\n"
        out << "c(#{color.red},#{color.green},#{color.blue})"
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
      out << "\n"
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
            mesh.add_polygon(polygon)
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

    def self.surface_outer_edges(surface)
      visible_edges = []
      surface.each do |face|
        face.edges.each do |edge|
          if not edge.soft?
            visible_edges << edge
          end
        end
      end
      visible_edges
    end

    def self.surface_from_face(face)
      surface = adjacent_faces(face)
    end

    def self.surface_test
      model = Sketchup.active_model
      face = model.selection[0]
      surface = surface_from_face(face)
      model.selection.clear
      outer_edges = surface_outer_edges(surface)
      sorted_edges = TT::Edges.sort(outer_edges)
      model.selection.add(sorted_edges)
      #border_verts = get_surface_border(surface)
      sorted_vertices = TT::Edges.sort_vertices(sorted_edges)
      #p border_verts
    end

    def self.adjacent_faces(face, faces_found = [])
      faces_found << face if faces_found.empty?
      edges = face.edges
      edges.each do |edge|
        if edge.soft?
          faces_to_add = edge.faces - faces_found
          faces_found.concat(faces_to_add)
          faces_to_add.each{|f| adjacent_faces(f, faces_found)}
        end
      end
      faces_found
    end

    def self.all_surfaces
      model = Sketchup.active_model
      if model.selection.length == 0
        all_faces = model.entities.grep(Sketchup::Face)
      else
        all_faces = model.selection.grep(Sketchup::Face)
      end
      #model.selection.clear
      #all_faces = model.entities.grep(Sketchup::Face)
      surfaces = []
      while(all_faces.size > 0)
        surface = surface_from_face(all_faces[0])
        surfaces << surface
        all_faces = all_faces - surface
      end
      surfaces
    end

    # @param [Sketchup::Edge] edge1
    # @param [Sketchup::Edge] edge2
    #
    # @return [Sketchup::Vertex|Nil]
    # @since 2.5.0
    def self.common_vertex(edge1, edge2)
      for v1 in edge1.vertices
        for v2 in edge2.vertices
          return v1 if v1 == v2
        end
      end
      nil
    end

    # Sorts the given set of edges from start to end. If the edges form a loop
    # an arbitrary start is picked.
    #
    # @todo Comment source
    #
    # @param [Array<Sketchup::Edge>] edges
    #
    # @return [Array<Sketchup::Edge>] Sorted set of edges.
    # @since 2.5.0
    def self.sort_edges( edges )
      if edges.is_a?( Hash )
        sort_from_hash( edges )
      elsif edges.is_a?( Enumerable )
        lookup = {}
        for edge in edges
          lookup[edge] = edge
        end
        sort_from_hash( lookup )
      else
        raise ArgumentError, '"edges" argument must be a collection of edges.'
      end
    end


    # Sorts the given set of edges from start to end. If the edges form a loop
    # an arbitrary start is picked.
    #
    # @param [Hash] edges Sketchup::Edge as keys
    #
    # @return [Array<Sketchup::Edge>] Sorted set of edges.
    # @since 2.5.0
    def self.sort_from_hash( edges )
      # Get starting edge - then trace the connected edges from either end.
      start_edge = edges.keys.first

      # Find the next left and right edge
      vertices = start_edge.vertices

      left = []
      for e in vertices.first.edges
        left << e if e != start_edge && edges[e]
      end

      right = []
      for e in vertices.last.edges
        right << e if e != start_edge && edges[e]
      end

      return nil if left.size > 1 || right.size > 1 # Check for forks
      left = left.first
      right = right.first

      # Sort edges from start to end
      sorted = [start_edge]

      # Right
      edge = right
      until edge.nil?
        sorted << edge
        connected = []
        for v in edge.vertices
          for e in v.edges
            connected << e if edges[e] && !sorted.include?(e)
          end
        end
        return nil if connected.size > 1 # Check for forks
        edge = connected.first
      end

      # Left
      unless sorted.include?( left ) # Fix: 2.6.0
        edge = left
        until edge.nil?
          sorted.unshift( edge )
          connected = []
          for v in edge.vertices
            for e in v.edges
              connected << e if edges[e] && !sorted.include?(e)
            end
          end
          return nil if connected.size > 1 # Check for forks
          edge = connected.first
        end
      end

      sorted
    end


    # @note The first vertex will also appear last if the curve forms a loop.
    #
    # Takes a sorted set of edges and returns a sorted set of vertices. Use
    # +TT::Edges.sort+ to sort a set of edges.
    #
    # @param [Array<Sketchup::Edge>] curve Set of sorted edge.
    #
    # @return [Array<Sketchup::Vertex>] Sorted set of vertices.
    # @since 2.5.0
    def self.sort_vertices(curve)
      return curve[0].vertices if curve.size <= 1
      vertices = []
      # Find the first vertex.
      common = self.common_vertex( curve[0], curve[1] ) # (?) Errorcheck?
      vertices << curve[0].other_vertex( common )
      # Now the rest can be added.
      curve.each { |edge|
        vertices << edge.other_vertex(vertices.last) # (?) Errorcheck?
      }
      return vertices
    end

    menu = UI.menu('Plugins').add_submenu('Need For Madness')
    menu.add_item('Show Code') { NFM.export }
    menu.add_item('NFM Import') { NFM.import } 
    #menu.add_item('NFM Surface Test') { NFM.surface_test } 

  end # module NFM
end # module JF
