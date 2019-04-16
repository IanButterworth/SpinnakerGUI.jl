# SpinnakerGUI.jl

using Spinnaker

# Main functions
function runCamera(;camid::Int64=0)
    global perfGrabFramerate
    global cam, camImage, camImageFrameBuffer, camRunning
    global camSettingsLimits

    camlist = Spinnaker.CameraList()
    if length(camlist) == 0
        error("No camera found")
    elseif length(camlist) > 1
        error("Multiple cameras found. Choice ambiguous.")
    else
        cam = camlist[camid]

        camSettingsLimitsUpdater!(cam,camSettingsLimits)

        start!(cam)
        camRunning = true

        camImage = Array{UInt8}(undef,camSettings.width,camSettings.height)

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
            end
            yield()
        end
        stop!(cam)
    end
end
