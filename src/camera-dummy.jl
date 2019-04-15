# dummycamera

dummycamTimer = nothing
exposurefactor = camSettings.exposureTime/12.0 #dummy setting to simulate ideal 12.0 time

# Typically imported functions
function getimage!(cam::String,image::Array{UInt8};normalize::Bool=false)
    image .= round.(UInt8,clamp.(rand(UInt8,size(image,1),size(image,2)).*exposurefactor,UInt8(0),UInt8(255)))
    wait(dummycamTimer)
end
function exposure!(cam::String)
    exposure = 12.0 #dummy value
    updateExposureFactor(exposure) #dummy brightness change
    return exposure
end
function exposure!(cam::String,exposure::Real)
    updateExposureFactor(exposure) #dummy brightness change
end
function start!(cam::String)
    global dummycamTimer
    dummycamTimer = Timer(0.0,interval=1/camSettings.acquisitionFramerate)
end
function stop!(cam::String)
    global dummycamTimer, camRunning
    close(dummycamTimer)
    dummycamTimer = nothing
end
function framerate!(cam::String,framerate::Real)
    global dummycamTimer
    dummycamTimer = Timer(0.0,interval=1/camSettings.acquisitionFramerate)
end

# Helper functions
function updateExposureFactor(exposure)
    global exposurefactor
    exposurefactor = exposure/12.0
end

# Main functions
function runCamera()
    global dummycamTimer
    global perfGrabFramerate
    global cam, camImage, camImageFrameBuffer, camRunning

    # Initialize dummy camera
    cam = "dummycam"
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
