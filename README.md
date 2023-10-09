# LivePhotoWallpaper - WIP
Create iOS 17 custom live wallpapers

# Procedure
1. Take a Live Photo on iOS Camera App.
2. Sync Live Photo to Mac via Photos App.
3. Export Live Photo as two parts by going to File -> Export -> Export Unmodified Original
4. Open custom .MOV in Premiere Pro, speed up the mideo to 1 second, and export it using the Live Wallpaper preset.
5. Open the .MP4 that was just exported in Quicktime and export it again as a .MOV.
5. Run Video Exporter on the Camera App's .MOV, the Camera App's .JPEG, and the custom .MOV that was just exported.
6. Open Live Photos App in Xcode and configure your phone to run it.
7. Drag the new .MOV, .HEIC pair that was just created into the Live Photos App directory in Xcode, change the input file names in the code, and run it.
8. Check the phone's Photos App to see if the Live Photo works.