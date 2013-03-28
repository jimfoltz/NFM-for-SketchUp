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
    @version = '0.5.1'
    @model = Sketchup.active_model
    @lvl = 0
    DEBUG = true

    if DEBUG
      LOG_FILE = "#{ENV['APPDATA']}/JimFoltz/SketchUp/NFM/log.txt"
      if not File.exists?("#{ENV['APPDATA']}/JimFoltz/SketchUp/NFM")
        Dir.mkdir("#{ENV['APPDATA']}/JimFoltz/SketchUp/NFM")
      end
      File.open("#{LOG_FILE}", "w") {|f| f.puts(Time.now)}
    end

    def self.log(s)
      if DEBUG
        File.open("#{LOG_FILE}", "a") {|f| f.puts(s)}
      end
    end

    def self.main
      log "in main"
      model = Sketchup.active_model
      sel = model.selection
      # Flip each vertex position on export to match NFM axes
      @tr = Geom::Transformation.rotation(ORIGIN, X_AXIS, 90.degrees)
      out = ''
      if sel.length > 0
        edges = sel.grep(Sketchup::Edge)
        if (edges.length == sel.length)
          export_selected_edges(edges, out)
        end
      end
      export(out)
      dialog(out)
    end

    def self.dialog(out)
      log "in dialog"
      if @wd and @wd.visible?
        @wd.close
      end

      # Show car code in dialog
      @wd = UI::WebDialog.new("NFM for SketchUp version #{@version}", false, 'JF\\NFM', 350, 500)
      @wd.set_html  <<-EOS
        <html>
        <head>
        <style>
        .menu {font: menu;}
        #area{height:90%;width:100%;}</style>
        </head>
        <body>
        Select all, Copy.<br>
        <div class=menu>
        <a href="skp:refresh">Refresh</a> |
        <a href="#" onclick="ta.focus();ta.select();">Select</a> |
        <a href="skp:import">Import</a>
        </div>
        <textarea id=area name=ta cols=40>#{out}</textarea>
        </body>
        <script>ta.focus(); ta.select();r=ta.createTextRange();r.execCommand('copy');</script>
        </html>
      EOS
      @wd.add_action_callback('refresh') do |d, a|
        JF::NFM.main
      end
      @wd.add_action_callback('import') do |d, a|
        JF::NFM.dialog_import
      end
      @wd.show
    end

    def self.export(out)
      log "in export" 
      model    = Sketchup.active_model
      entities = model.active_entities
      log "all_surfaces"
      surfaces = all_surfaces
      if surfaces.size > 210
        UI.messagebox("Model has #{surfaces.size} surfaces.")
      end
      model.selection.clear
      surfaces.each do |surface|
        if surface.length < 1
          model.selection.clear
          model.selection.add surface
          fail surface.inspect
        end
        outer_edges = surface_outer_edges(surface)
        model.selection.add(outer_edges)
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
        export_vertices(sorted_verts, out)
        out << '</p>'
        out << "\n"
        out << "\n"
      end # surfaces.each 

      # Output default wheels, stats and physics
      #out << "// Default Wheels\ngwgr(0)\nrims(140,140,140,18,10)\n"
      #out << "w(-45,15,76,11,26,20)\nw(45,15,76,11,-26,20)\n"
      #out << "gwgr(0)\nrims(140,140,140,18,10)\n"
      #out << "w(-45,15,-76,0,26,20)\nw(45,15,-76,0,-26,20)\n"
      #out << "\nstat(128,98,102,109,123)\n"
      #out << "\nphysics(50,50,50,50,50,50,50,50,50,50,50,50,50,50,0,4753)\n"

    end # def export

    def self.export_selected_edges(edges, out)
      sorted_edges = sort_edges(edges)
      sorted_verts = sort_vertices(sorted_edges)
      out << "<p>\n"
      export_vertices(sorted_verts, out)
      out << "</p>\n\n"
    end

    def self.export_vertices(verts, out)
      # Try rotate verts to fix concave surfaces in nfm
      #10.times {verts.push(verts.pop)}
        verts.each do |vert|
          pos = vert.position
          pos.transform!(@tr)
          pos = pos.to_a.map{|e| e.round}
          out << 'p(' << pos.join(',') << ')' 
          out << "\n"
        end
    end

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

    def self.dialog_import
      lines = @wd.get_element_value('area').split("\n")
      import(lines)
    end

    def self.file_import
      file = UI.openpanel
      lines = IO.readlines(file)
      dialog(lines)
      import(lines)
    end

    def self.import(lines)
      model = Sketchup.active_model
      model.start_operation("NFM Import from Dialog", true)
      if model.active_entities.length > 0
        grp = model.active_entities.add_group
        ents = grp.entities
      else
        ents = model.active_entities
      end
      tr = Geom::Transformation.rotation(ORIGIN, X_AXIS, -90.degrees)
      #p file
      in_p = false
      mesh = Geom::PolygonMesh.new
      polygon = []
      #IO.foreach(file) do |line|
      lines.each do |line|
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
            ents.add_faces_from_mesh(mesh, 0)
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
      #entities = Sketchup.active_model.entities
      ents.transform_entities(tr, ents.to_a)
      Sketchup.active_model.active_view.zoom_extents
      p ents[0].parent
      if ents[0].parent.is_a?(Sketchup::ComponentDefinition)
        ents[0].parent.invalidate_bounds
      end
      model.commit_operation
    end

    def self.surface_outer_edges(surface)
      visible_edges = []
      surface.each do |face|
        face.outer_loop.edges.each do |edge|
          if not edge.soft?
            visible_edges << edge
          end
        end
      end
      visible_edges
    end

    def self.surface_from_face(face)
      log "in surface_from_face"
      surface = adjacent_faces(face)
    end

    def self.adjacent_faces(face, faces_found = [])
      log "in adjacent_faces"
      @lvl += 1
      log "level #{@lvl}"
      faces_found << face if faces_found.empty?
      edges = face.edges
      edges.each do |edge|
        if edge.soft? and edge.smooth?
          faces_to_add = edge.faces - faces_found
          faces_found.concat(faces_to_add)
          faces_to_add.each{|f| adjacent_faces(f, faces_found)}
        end
      end
      faces_found
    end

    def self.all_surfaces
      log "in all_surfaces"
      model = Sketchup.active_model
      if model.selection.length == 0
        all_faces = model.entities.grep(Sketchup::Face)
      else
        all_faces = model.selection.grep(Sketchup::Face)
      end
      surfaces = []
      while(all_faces.size > 0)
        surface = surface_from_face(all_faces[0])
        surfaces << surface
        all_faces = all_faces - surface
      end
      log "out all_surfaces"
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
      # Unappend duplicate vert
      vertices.pop
      return vertices
    end

    def self.round_vertices
      model = Sketchup.active_model
      all_verts = {}
      vecs = []
      edges = model.entities.grep(Sketchup::Edge)
      edges.each do |edge|
        edge.vertices.each do |vertex|
          if not all_verts.include?(vertex)
            all_verts[vertex] = vertex.position
          end
        end
      end
      verts = []
      # build vecs
      all_verts.each do |vert, pos|
        verts << vert
        rvert = [pos.x.round, pos.y.round, pos.z.round]
        vecs << (pos.vector_to(rvert))
      end
      warn "mis-matched verts/vecs" unless verts.length == vecs.length
      model.entities.transform_by_vectors(verts, vecs)
      model.active_view.refresh
    end

    def self.surface_test
      model = Sketchup.active_model
      face = model.selection[0]
      surface = surface_from_face(face)
      model.selection.clear
      outer_edges = surface_outer_edges(surface)
      model.selection.add(outer_edges)
      return
      sorted_edges = TT::Edges.sort(outer_edges)
      model.selection.add(sorted_edges)
      #border_verts = get_surface_border(surface)
      sorted_vertices = TT::Edges.sort_vertices(sorted_edges)
      #p border_verts
    end

    menu = UI.menu('Plugins').add_submenu('Need For Madness')
    menu.add_item('Show Code') { NFM.main }
    menu.add_item('NFM Dialog Import') { NFM.dialog_import } 
    menu.add_item('NFM File Import') { NFM.file_import } 
    #menu.add_item('NFM Surface Test') { NFM.surface_test } 
    if DEBUG
      menu.add_separator
      menu.add_item('NFM Round Verts') { NFM.round_vertices } 
      menu.add_item("View Log") { UI.openURL(LOG_FILE) }
    end

  end # module NFM
end # module JF
