# SpinnakerGUI.jl

using Spinnaker

function cam_init(;camid::Int64=0)
    camlist = Spinnaker.CameraList()
    if length(camlist) == 0
        error("No camera found")
    else
        cam = camlist[camid]
    end
    return cam
end
# Main functions
function runCamera()
    global perfGrabFramerate
    global cam, camImage, camImageFrameBuffer, camRunning
    global camSettings, camSettingsLimits


    camSettingsLimitsUpdater!(cam,camSettingsLimits)
    camSettings.width = camSettingsLimits.width[2]
    camSettings.height = camSettingsLimits.height[2]
    camImage = Array{UInt8}(undef,camSettings.width,camSettings.height)
    imagedims!(cam,(camSettings.width,camSettings.height))

    start!(cam)
    camRunning = true

    perfGrabTime = time()
    while gui_open
        if camRunning
            #cim_id, cim_timestamp, cim_exposure = getimage!(camera, previewimage)
            try
                getimage!(cam,camImage,normalize=false)
            catch err
                if err isa EOFError
                    # Do nothing. This happens if the camera is stopped before the camRunning
                    # bool is set due to async
                else
                    rethrow()
                end
            end
            # Loop timing
            perfGrabFramerate = 1/(time() - perfGrabTime)
            perfGrabTime = time()
        else
            println("cam not running (grab)")
        end
        yield()
    end
    stop!(cam)
    camRunning = false

end
