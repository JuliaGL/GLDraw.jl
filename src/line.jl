using GLAbstraction, ModernGL, GLWindow, GLFW


window 	= createwindow("GLPlot", 1500,1000, windowhints=[(GLFW.SAMPLES, 0)]) 
ocamera = OrthographicCamera(window.inputs)

view = [
  "GLSL_EXTENSIONS"     => "#extension GL_ARB_draw_instanced : enable",
]

points = [Vec3(i, sin(i), 0) for i=0:0.1:2pi]

data = [
:vertex         	=> GLBuffer(Float32[1:4], 1), # simple quad
:index          	=> indexbuffer(GLuint[0, 1, 2, 2, 3, 0]),

:points 			=> Texture(points),
:linewidth 			=> 0.01f0,
:shadow 			=> 0.01f0,
:projection			=> ocamera.projection,
:view 				=> ocamera.view 	
]

program = TemplateProgram(
	Pkg.dir("GLDraw","src","line.vert"), Pkg.dir("GLDraw","src","line.frag"), 
	view=view, attributes=data, fragdatalocation=[(0, "fragment_color"),(1, "fragment_objectid")]
)
obj = instancedobject(data, program, length(points)-1)
prerender!(obj, enabletransparency)

glClearColor(1, 1, 1, 1.0)

while !GLFW.WindowShouldClose(window.glfwWindow)
    yield()
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    
    render(obj)
    
    GLFW.SwapBuffers(window.glfwWindow)
	GLFW.PollEvents()
end
GLFW.Terminate()
