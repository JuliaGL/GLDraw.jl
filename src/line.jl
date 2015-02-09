using GLAbstraction, ModernGL, GLWindow, GLFW


window 	= createwindow("GLPlot", 1920,1280, windowhints=[(GLFW.SAMPLES, 0)]) 
ocamera = OrthographicPixelCamera(window.inputs)



points = Vec3[Vec3(sin(i), i, 0) * 100f0 for i=0:0.1:2pi]

data = [
:vertex         	=> GLBuffer(Float32[1:4], 1), # simple quad
:index          	=> indexbuffer(GLuint[0, 1, 2, 2, 3, 0]),

:points 			=> Texture(points),
:linewidth 			=> 20f0,
:shadow 			=> 0.0f0,
:projection			=> ocamera.projection,
:view 				=> ocamera.view,
]

program = TemplateProgram(
	Pkg.dir("GLDraw","src","line.vert"), Pkg.dir("GLDraw","src","line.frag"), 
	attributes=data, fragdatalocation=[(0, "fragment_color"),(1, "fragment_objectid")]
)
obj = instancedobject(data, length(points)-3, program)
prerender!(obj, enabletransparency)

glClearColor(1, 1, 1, 1.0)

while !GLFW.WindowShouldClose(window.nativewindow)
    yield()
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    glViewport(0,0,window.inputs[:framebuffer_size].value...)
    render(obj)
    
    GLFW.SwapBuffers(window.nativewindow)
	GLFW.PollEvents()
end
GLFW.Terminate()
