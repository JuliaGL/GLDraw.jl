using ImmutableArrays

function normal(a, b)
    dx = b[1] - a[1]
    dy = b[2] - a[2]
    c = sqrt(dx * dx + dy * dy)
    return Vector2(dx/c, dy/c)
end
function dist(a, b)
    dx = b[1] - a[1]
    dy = b[2] - a[2]
    c = sqrt(dx * dx + dy * dy)
    return c
end

typealias Coordinate Vector2{Int16} 

function add{VertexType, }(buffer, x::VertexType, y::VertexType, ex::FloatingPoint, ey::FloatingPoint, tx::Int8, ty::Int8, linesofar::Int32) {
    idx = length(buffer);
    coords::Int16 = static_cast<int16_t *>(data);
    coords[0] = (x * 2) | tx;
    coords[1] = (y * 2) | ty;
    int8_t *extrude = static_cast<int8_t *>(data);
    extrude[4] = std::round(extrudeScale * ex);
    extrude[5] = std::round(extrudeScale * ey);
    coords[3] = linesofar;
    return idx;
end

function addGeometry(vertices) 
    # TODO: use roundLimit
    # const float roundLimit = geometry.round_limit

    if length(vertices) < 2
        error("a line must have at least two vertices\n")
    end

    firstVertex = first(vertices)
    lastVertex  = last(vertices)
    closed      = firstVertex[1] == lastVertex[1] && firstVertex[2] == lastVertex[2]

    if length(vertices) == 2 && closed
        # fprintf(stderr, "a line may not have coincident points\n")
        return
    end

    beginCap    = properties.cap
    endCap      = closed ? CapType.Butt : properties.cap

    currentJoin = JoinType.Miter

    currentVertex   = Coordinate(0, 0)
    prevVertex      = Coordinate(0, 0)
    nextVertex      = Coordinate(0, 0)
    prevNormal      = Vector(0.0)
    nextNormal      = Vector(0.0)

    EType       = Int32
    e1          = -one(EType)
    e2          = -one(EType)
    e3          = -one(EType)

    flip        = one(Int8)
    distance    = 0.0

    if (closed) 
        currentVertex   = vertices[end - 2]
        nextNormal      = normal(currentVertex, lastVertex)
    end

    start_vertex = convert(Int32, vertexBuffer.index())

    triangle_store
    point_store

    for i=1:length(vertices)

        if nextNormal
            prevNormal = Vec2(-nextNormal[1], -nextNormal[2]) 
        end
        if currentVertex
            prevVertex = currentVertex
        end

        currentVertex   = vertices[i]
        currentJoin     = properties.join

        if prevVertex
            distance += dist(currentVertex, prevVertex)
        end

        # Find the next vertex.
        if i + 1 < length(vertices)
            nextVertex = vertices[i + 1]
        else 
            nextVertex = Coordinate(0, 0)
        end

        # If the line is closed, we treat the last vertex like the first vertex.
        if (!nextVertex && closed) 
            nextVertex = vertices[1]
        end

        if (nextVertex) 
            # if two consecutive vertices exist, skip one
            (currentVertex[1] == nextVertex[1] && currentVertex[2] == nextVertex[2]) && continue
        end

        # Calculate the normal towards the next vertex in this line. In case
        # there is no next vertex, pretend that the line is continuing straight,
        # meaning that we are just reversing the previous normal
        if (nextVertex) 
            nextNormal = normal(currentVertex, nextVertex)
        else 
            nextNormal = Vector2(-prevNormal[1], -prevNormal[2])
        end

        # If we still don't have a previous normal, this is the beginning of a
        # non-closed line, so we're doing a straight "join".
        if (!prevNormal) 
            prevNormal = Vector2(-nextNormal[1], -nextNormal[2])
        end

        # Determine the normal of the join extrusion. It is the angle bisector
        # of the segments between the previous line and the next line.
        joinNormal = Vector2(
            prevNormal[1] + nextNormal[1],
            prevNormal[2] + nextNormal[2]
        )

        # Cross product yields 0..1 depending on whether they are parallel
        # or perpendicular.
        joinAngularity = nextNormal[1] * joinNormal[2] - nextNormal[2] * joinNormal[1]
        joinNormal[1] /= joinAngularity
        joinNormal[2] /= joinAngularity
        roundness::Float64 = max(abs(joinNormal[1]), abs(joinNormal[2]))


        # Switch to miter joins if the angle is very low.
        if (currentJoin != JoinType.Miter) 
            if (abs(joinAngularity) < 0.5 && roundness < properties.miter_limit) 
                currentJoin = JoinType.Miter
            end
        end

        # Add offset square begin cap.
        if (!prevVertex && beginCap == CapType.Square) 
            # Add first vertex
            e3::Int32 = vertexBuffer.add(currentVertex[1], currentVertex[2], # vertex pos
                                   flip * (prevNormal[1] + prevNormal[2]), flip * (-prevNormal[1] + prevNormal[2]), # extrude normal
                                   0, 0, distance) - start_vertex # texture normal

            if (e1 >= 0 && e2 >= 0 && e3 >= 0) 
                triangle_store.emplace_back(e1, e2, e3)
            end
            e1::Int32 = e2 
            e2::Int32 = e3

            # Add second vertex
            e3::Int32 = vertexBuffer.add(currentVertex[1], currentVertex[2], # vertex pos
                                   flip * (prevNormal[1] - prevNormal[2]), flip * (prevNormal[1] + prevNormal[2]), # extrude normal
                                   0, 1, distance) - start_vertex # texture normal

            if (e1 >= 0 && e2 >= 0 && e3 >= 0) 
                triangle_store.emplace_back(e1, e2, e3)
            end
            e1::Int32 = e2 
            e2::Int32 = e3
        end

        # Add offset square end cap.
        else if (!nextVertex && endCap == CapType.Square) 
            # Add first vertex
            e3::Int32 = (int32_t)vertexBuffer.add(currentVertex[1], currentVertex[2], # vertex pos
                                   nextNormal[1] - flip * nextNormal[2], flip * nextNormal[1] + nextNormal[2], # extrude normal
                                   0, 0, distance) - start_vertex # texture normal

            if (e1 >= 0 && e2 >= 0 && e3 >= 0) 
                triangle_store.emplace_back(e1, e2, e3)
            end

            e1::Int32 = e2 
            e2::Int32 = e3

            # Add second vertex
            e3::Int32 = (int32_t)vertexBuffer.add(currentVertex[1], currentVertex[2], # vertex pos
                                   nextNormal[1] + flip * nextNormal[2], -flip * nextNormal[1] + nextNormal[2], # extrude normal
                                   0, 1, distance) - start_vertex # texture normal

            if (e1 >= 0 && e2 >= 0 && e3 >= 0) 
                triangle_store.emplace_back(e1, e2, e3)
            end
            e1::Int32 = e2 
            e2::Int32 = e3
        end

        else if (currentJoin == JoinType.Miter) 
            # MITER JOIN
            if (abs(joinAngularity) < 0.01) 
                # The two normals are almost parallel.
                joinNormal[1] = -nextNormal[2]
                joinNormal[2] = nextNormal[1]
            elseif roundness > properties.miter_limit
                # If the miter grows too large, flip the direction to make a
                # bevel join.
                joinNormal[1] = (prevNormal[1] - nextNormal[1]) / joinAngularity
                joinNormal[2] = (prevNormal[2] - nextNormal[2]) / joinAngularity
            end

            if roundness > properties.miter_limit
                flip = -flip
            end

            # Add first vertex
            e3::Int32 = (int32_t)vertexBuffer.add(currentVertex[1], currentVertex[2], # vertex pos
                                   flip * joinNormal[1], flip * joinNormal[2], # extrude normal
                                   0, 0, distance) - start_vertex # texture normal

            if (e1 >= 0 && e2 >= 0 && e3 >= 0) 
                triangle_store.emplace_back(e1, e2, e3)
            end
            e1::Int32 = e2 
            e2::Int32 = e3

            # Add second vertex
            e3::Int32 = (int32_t)vertexBuffer.add(currentVertex[1], currentVertex[2], # vertex pos
                                   -flip * joinNormal[1], -flip * joinNormal[2], # extrude normal
                                   0, 1, distance) - start_vertex # texture normal

            if (e1 >= 0 && e2 >= 0 && e3 >= 0) 
                triangle_store.emplace_back(e1, e2, e3)
            end

            e1::Int32 = e2 
            e2::Int32 = e3

            if ((!prevVertex && beginCap == CapType.Round) ||
                    (!nextVertex && endCap == CapType.Round)) 
                point_store.emplace_back(e1)
            end
        else 
            # Close up the previous line
            # Add first vertex
            e3::Int32 = (int32_t)vertexBuffer.add(currentVertex[1], currentVertex[2], # vertex pos
                                   flip * prevNormal[2], -flip * prevNormal[1], # extrude normal
                                   0, 0, distance) - start_vertex # texture normal

            if (e1 >= 0 && e2 >= 0 && e3 >= 0) triangle_store.emplace_back(e1, e2, e3)
            e1::Int32 = e2 
            e2::Int32 = e3

            # Add second vertex.
            e3 = (int32_t)vertexBuffer.add(currentVertex[1], currentVertex[2], # vertex pos
                                   -flip * prevNormal[2], flip * prevNormal[1], # extrude normal
                                   0, 1, distance) - start_vertex # texture normal

            if (e1 >= 0 && e2 >= 0 && e3 >= 0) triangle_store.emplace_back(e1, e2, e3)
            e1::Int32 = e2 
            e2::Int32 = e3

            prevNormal = Vector2(-nextNormal[1], -nextNormal[2])
            flip = 1

            # begin/end caps
            if ((!prevVertex && beginCap == CapType.Round) ||
                    (!nextVertex && endCap == CapType.Round)) 
                point_store.emplace_back(e1)
            end


            if (currentJoin == JoinType.Round) 
                if (prevVertex && nextVertex && (!closed || i > 0)) 
                    point_store.emplace_back(e1)
                end

                # Reset the previous vertices so that we don't accidentally create
                # any triangles.
                e1::Int32 = -1 
                e2::Int32 = -1 
                e3::Int32 = -1
            end

            # Start the new quad.
            # Add first vertex
            e3::Int32 = vertexBuffer.add(currentVertex[1], currentVertex[2], # vertex pos
                                   -flip * nextNormal[2], flip * nextNormal[1], # extrude normal
                                   0, 0, distance) - start_vertex # texture normal

            if (e1 >= 0 && e2 >= 0 && e3 >= 0) 
                triangle_store.emplace_back(e1, e2, e3)
            end
            e1::Int32 = e2 
            e2::Int32 = e3

            # Add second vertex
            e3::Int32 = vertexBuffer.add(currentVertex[1], currentVertex[2], # vertex pos
                                   flip * nextNormal[2], -flip * nextNormal[1], # extrude normal
                                   0, 1, distance) - start_vertex # texture normal

            if (e1 >= 0 && e2 >= 0 && e3 >= 0) 
                triangle_store.emplace_back(e1, e2, e3)
            end

            e1::Int32 = e2 
            e2::Int32 = e3
        end
    end

    end_vertex      = length(vertexBuffer)
    vertex_count    = end_vertex - start_vertex

    # Store the triangle/line groups.
    
        if (!length(triangleGroups) || (last(triangleGroups).vertex_length + vertex_count > 65535)) 
            # Move to a new group because the old one can't hold the geometry.
            triangleGroups.emplace_back()
        end

        group = last(triangleGroups)
        for triangle in triangle_store 
            triangleElementsBuffer.add(
                group.vertex_length + triangle.a,
                group.vertex_length + triangle.b,
                group.vertex_length + triangle.c
            )
        end

        group.vertex_length += vertex_count
        group.elements_length += triangle_store.size()
    end

    # Store the line join/cap groups.
    
        if (!length(pointGroups) || (last(pointGroups).vertex_length + vertex_count > 65535)) 
            # Move to a new group because the old one can't hold the geometry.
            pointGroups.emplace_back()
        end

        group = last(pointGroups)
        for (PointElement point : point_store) 
            pointElementsBuffer.add(group.vertex_length + point)
        end

        group.vertex_length += vertex_count
        group.elements_length += point_store.size()
    end
end