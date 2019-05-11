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
    global sessionStat
    global camImageFrameBuffer

    camImage = Array{UInt8}(undef,camSettings.width,camSettings.height)

    start!(cam)
    camSettingsLimitsRead!(cam,camSettingsLimits) #some things change once running

    perfGrabTime = time()
    grabNotRunningTimer = Timer(0.0,interval=1/5)
    firstframe = true
    while !sessionStat.terminate
        if isrunning(cam)
            firstframe && (camImage = Array{UInt8}(undef,camSettings.width,camSettings.height))
            firstframe = false
            try
                cim_id, cim_timestamp, cim_exposure = getimage!(cam,camImage,normalize=false,timeout=0)
                if sessionStat.recording
                    push!(camImageFrameBuffer,camImage)
                end
                # Loop timing
                perfGrabFramerate = 1/(time() - perfGrabTime)
                perfGrabTime = time()
            catch err
                if occursin("SPINNAKER_ERR_TIMEOUT(-1011)",sprint(showerror, err))
                    # No frame available
                    #println("No frame available")
                elseif err isa EOFError || occursin("SPINNAKER_ERR_IO(-1010)",sprint(showerror, err))
                    @warn "Noncritical framegrab error"
                else
                    rethrow()
                end
            end
            yield()
        else
            firstframe = true
            wait(grabNotRunningTimer)
            #println("Not running")
        end

    end
    isrunning(cam) && stop!(cam)

end
