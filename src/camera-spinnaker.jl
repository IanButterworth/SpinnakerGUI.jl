# SpinnakerGUI.jl

using Spinnaker

function cam_init(;camid::Int64=0)
    global camSettings
    camlist = Spinnaker.CameraList()
    if length(camlist) == 0
        error("No camera found")
    else
        cam = camlist[camid]
        camSettingsRead!(cam,camSettings)
        camSettingsLimitsRead!(cam,camSettingsLimits)
        buffermode!(cam,"NewestOnly")
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
                cim_id, cim_timestamp, cim_exposure = getimage!(cam,camImage,normalize=false,timeout=0)
                firstframe = false
                # Loop timing
                perfGrabFramerate = 1/(time() - perfGrabTime)
                perfGrabTime = time()
            catch err
                if occursin("SPINNAKER_ERR_TIMEOUT(-1011)",sprint(showerror, err))
                    # No frame available
                elseif err isa EOFError || occursin("SPINNAKER_ERR_IO(-1010)",sprint(showerror, err))
                    @warn "Framegrab error"
                else
                    rethrow()
                end
            end
            yield()
        else
            firstframe = true
            wait(grabNotRunningTimer)
        end

    end
    isrunning(cam) && stop!(cam)

end
