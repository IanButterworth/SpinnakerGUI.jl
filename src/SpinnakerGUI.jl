module SpinnakerGUI

include("utils.jl")

# camera settings
include("camera-settings.jl")
cam = nothing
sessionStat = sessionStatus()
camSettings = settings()
camSettingsLimits = settingsLimits()
camGPIO = GPIO()
camGPIOLimits = GPIOLimits()

# Load camera framework
ENV["USE_DUMMYCAM"] = 0         #Force dummycam
@static if Sys.isapple() || ENV["USE_DUMMYCAM"]=="1"  # Spinnaker not currently available for MacOS or CI testing
    include("camera-dummy.jl")
else
    include("camera-spinnaker.jl")
end

# global image buffers
camImage = nothing
camImageFrameBuffer = Vector{Array{UInt8}}(undef,0)

# GUI settings
gui_open = nothing
control_open = true

# performance reporting
perfGrabFramerate = 0.0

include("gui.jl")
include("recording.jl")

function start(;camid::Int64=0)
    global cam, gui_open

    cam = cam_init(camid=camid)

    gui_open = true # Async means you have to assume it's open - could be improved
    # Start gui (operates asynchronously at at ~60 FPS)
    @info "Starting GUI (async)"
    @async_errhandle gui(timerInterval=1/60)

    # Start settings updater (operates asynchronously at at ~10 FPS)
    @info "Starting Camera Settings Updater (async)"
    @async_errhandle camSettingsUpdater(timerInterval=1/10)

    # Start recording listener
    @info "Starting recording listener (async)"
    @async_errhandle videowritelistener()

    # Run camera control with priority
    @info "Starting Camera Acquisition"
    runCamera()

    @info "SpinnakerGUI: Successful exit"

end


export start

end
