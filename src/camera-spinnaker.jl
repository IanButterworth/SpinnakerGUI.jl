# SpinnakerGUI.jl

using Spinnaker

function cam_init(;camid::Int64=0)
    global camSettings
    @info "Checking for cameras"
    camlist = Spinnaker.CameraList()
    if length(camlist) == 0
        error("No camera found")
    else
        @info "Selecting camera $camid"
        cam = camlist[camid]
        @info "Reading settings from camera"
        camSettingsRead!(cam,camSettings)
        camSettingsLimitsRead!(cam,camSettingsLimits)
        buffermode!(cam,"NewestOnly")
        @info "Camera ready"
    end
    return cam
end
# Main functions
function runCamera()
    global perfGrabFramerate
    global cam, camImage, camImageFrameBuffer
    global camSettings, camSettingsLimits

    camImage = Array{UInt8}(undef,camSettings.width,camSettings.height)

    start!(cam)
    camSettingsLimitsRead!(cam,camSettingsLimits) #some things change once running


    perfGrabTime = time()
    grabNotRunningTimer = Timer(0.0,interval=1/5)
    firstframe = true
    while gui_open
        if isrunning(cam)
            firstframe && (camImage = Array{UInt8}(undef,camSettings.width,camSettings.height))
            try
                cim_id, cim_timestamp, cim_exposure = getimage!(cam,camImage,normalize=false,timeout=1000)
                firstframe = false
            catch err
                if err isa EOFError || occursin("SPINNAKER_ERR_IO(-1010)",sprint(showerror, err))
                    @warn "Framegrab error"
                else
                    rethrow()
                end
            end
            # Loop timing
            perfGrabFramerate = 1/(time() - perfGrabTime)
            perfGrabTime = time()
            yield()
        else
            firstframe = true
            wait(grabNotRunningTimer)
        end

    end
    isrunning(cam) && stop!(cam)

end
