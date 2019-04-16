module SpinnakerGUI

include("utils.jl")

# camera settings
include("camera-settings.jl")
cam = nothing
camSettings = settings()
camSettingsLimits = settingsLimits()
camGPIO = GPIO()
camGPIOLimits = GPIOLimits()

# Load camera framework
ENV["USE_DUMMYCAM"] = 1         #Force dummycam
@static if Sys.isapple() || ENV["USE_DUMMYCAM"]=="1"  # Spinnaker not currently available for MacOS or CI testing
    include("camera-dummy.jl")
else
    include("camera-spinnaker.jl")
end

# global image buffers
camImage = nothing
camImageFrameBuffer = nothing

# GUI settings
gui_open = true
control_open = true

# performance reporting
perfGrabFramerate = 0.0


include("gui.jl")

function start()
    global gui_open
    gui_open = true # Async means you have to assume it's open - could be improved 
    # Start gui (operates asynchronously at at ~60 FPS)
    @async_errhandle gui(timerInterval=1/60)

    # Start settings updater (operates asynchronously at at ~10 FPS)
    @async_errhandle camSettingsUpdater(timerInterval=1/10)

    # Run camera control with priority
    runCamera()

    @info "SpinnakerGUI: Successful exit"

end


export start

end
