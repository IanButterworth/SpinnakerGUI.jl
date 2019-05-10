using VideoIO, Dates


```
videowritelistener(;compression=0,overwrite=false, fps=60.0, options=``)
Write video to file

Based on https://discourse.julialang.org/t/creating-a-video-from-a-stack-of-images/646/8
Reference for H.264: https://trac.ffmpeg.org/wiki/Encode/H.264#LosslessH.264
The range of the compression (CRF) scale is 0–51, where 0 is lossless, 23 is the default, and 51 is worst quality possible
```
function videowritelistener(;compression=0,overwrite=false, fps=60.0, options=``)

    ow = overwrite ? `-y` : `-n`
    crf = compression
    preset = compression == 0 ? "ultrafast" : "medium"
    ffmpegpath = VideoIO.ffmpeg

    global sessionStat
    global camImageFrameBuffer

    while !sessionStat.terminate
        if length(camImageFrameBuffer) > 0
            sessionStat.savedframes = 0
            fname = string(Dates.format(now(), "yyyy-mm-dd_HHMMSS"),".avi")
            h, w = size(camImageFrameBuffer[1])
            withenv("PATH" => VideoIO.libpath, 
                "LD_LIBRARY_PATH" => VideoIO.libpath, 
                "DYLD_LIBRARY_PATH" => VideoIO.libpath) do
                open(`$ffmpegpath
                    -loglevel warning
                    $ow -f rawvideo -pix_fmt gray -s:v $(h)x$(w)
                    -r $fps -i pipe:0 -c:v libx264 -preset: $preset
                    -crf $crf -pix_fmt yuv422p
                    $options -vf "transpose=1,pad=ceil($w/2)\*2:ceil($h/2)\*2"
                    $fname`, "w") do out
                    while length(camImageFrameBuffer) > 0 || sessionStat.recording || !sessionStat.terminate
                        while length(camImageFrameBuffer) == 0 && sessionStat.recording
                            yield() #wait without blocking during recording time
                        end
                        if length(camImageFrameBuffer) >0
                            write(out, camImageFrameBuffer[1])
                            deleteat!(camImageFrameBuffer,1)
                        end
                        sessionStat.bufferedframes = length(camImageFrameBuffer)
                        sessionStat.savedframes += 1
                        yield()
                    end
                end
            end
        end
        yield()
    end
end
