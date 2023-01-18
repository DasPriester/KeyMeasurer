# KeyMeasurer
University image processing project

## Description

This project is a simple image processing application that allows the user to detect and profile a key, resulting in an ID.

This application uses the MATLAB Application Designer to create a GUI that allows the user to connect a webcam and take a picture or video of a key.

The application then uses MATLAB's image processing toolbox to detect the key and profile it, resulting in an ID.

## Installation
### Requirements
- [MATLAB](https://www.mathworks.com/products/matlab.html)
  - Image Processing Toolbox
  - Image Acquisition Toolbox
  - Computer Vision Toolbox
  - USB Web Camera Support Package
### Instructions
1. [Download](https://github.com/DasPriester/KeyMeasurer/archive/refs/heads/main.zip) the repository
2. Open MATLAB
3. Open the [Project_app.mlapp](Projekt_app.mlapp) file in the MATLAB application designer
4. Run the application

## Usage
### Getting Started
1. Select a webcam by clicking on an entry of the [Webcam Selector](#webcam-selector)
2. Press the [Start Button](#start-button) to start feeding the webcam to the application
### Taking a Picture
1. Press the [Picture Button](#picture-button) to take a picture of the key
2. When the frame around the [Camera Feed](#camera-feed) turns green, a key has been detected
3. Copy the ID from the [ID Field](#id-field) 
### Taking a Video
1. Press the [Video Button](#video-button) to start recording a video of the key
2. When the frame around the [Camera Feed](#camera-feed) turns green, a key has been detected
3. Copy the ID from the [ID Field](#id-field)
### Quitting
1. Press the [Start Button](#start-button)  again to stop the webcam feed
2. Close the application or press the stop button inside the MATLAB application designer

## Help
### FAQ
"My webcam is not detected"
- If no webcam is detected make sure that your webcam is connected and that the USB Web Camera Support Package is installed
- Make sure other applications can access your webcam
- Hit the "Refresh" button to try again

"My key is not detected (the frame around the camera feed is not green)"
- Make sure that the key is in the frame of the camera feed (The application will not detect keys that are on the sides of the frame due to the cropping of the image)
- Check if other keys are detected by the application (The application will only detect one key at a time)
- Go to the [Debug tab](#debug-tab) and uncheck the [Only valid checboxk](#only-valid-checkbox) to see if the key is maybe not matching the validity criteria

"The ID keeps changing/is not the same as previous IDs of the same key"
- Our application uses a simple algorithm to turn the profile of a key into an ID, this algorithm is still in development and might not work at the moment
  
### Debugging Tools
- The [Debug tab](#debug-tab) contains a few tools to help you live edit some of the parameters of the detection algorithm
- Check the [idKey.m](idKey.m) file to see how the ID is calculated. MATLAB can be used to debug this file
- The Applications code can be found in the [Projekt_app.mlapp](Projekt_app.mlapp) file. Open it in the MATLAB application designer to debug the application

### Buttons and Fields
#### Main tab
  - Webcam Selector<a id="webcam-selector"></a>
    - Location: Top right
    - Description: List of all connected webcams. Select a webcam by clicking on an entry
#### Debug tab
  - Only valid checkbox<a id="only-valid-checkbox"></a>
    - Location: Bottom right
    - Description: Hides all keys that are not valid when checked
  - Edge Detection / Segmentation / Rotation Plots<a id="esr-plots"></a>
    - Location: Center
    - Description: Plots of the edge detection, segmentation and rotation steps of the key detection algorithm
  - Extra Plot<a id="extra-plot"></a>
    - Location: Bottom right
    - Description: Extra plot for debugging. Can be used to plot the Mask, Key or Label steps of the key detection algorithm. Change the value of the [Extra Plot](#extra-plot) field by right clicking on the background of the application (not a button, field or plot) and selecting [Extra Plot](#extra-plot) -> ...
  - Framerate Field<a id="framerate-field"></a>
    - Location: Top left
    - Description: Sets the framerate of the camera feed
  - Recording Indicator<a id="recording-indicator"></a>
    - Location: Top left
    - Description: Indicates if the application is recording a video
  - Resolution Field<a id="resolution-field"></a>
    - Location: Bottom left
    - Description: Sets the resolution of the processed image
  - Closing 1/2 Field<a id="closing-field"></a>
    - Location: Bottom left
    - Description: Sets the divisor for the closing operations of the key detection algorithm. The lower the value, the bigger the closing element.\
  _1_ for closing gaps between segments of the edge detection.\
  _2_ for closing gaps between segments of the segmentation
  - Theta / Alpha Field<a id="theta-alpha-field"></a>
    - Location: Bottom left
    - Description: Shows the angle of the key in degrees.\
  _Alpha_ is the angle of the key in the image.\
    _Theta_ is the angle of the rotated key that is used to shear the image
  - k_len Field<a id="k_len-field"></a>
    - Location: Bottom left
    - Description: Shows the length of the key in pixels
#### Both tabs
  - Camera Feed<a id="camera-feed"></a>
    - Location: Left
    - Description: The camera feed of the selected webcam
  - Start Button<a id="start-button"></a>
    - Location: Top left
    - Description: Starts the webcam feed
  - Picture Button<a id="picture-button"></a>
    - Location: Top left
    - Description: Takes a picture with the webcam
  - Video Button<a id="video-button"></a>
    - Location: Top left
    - Description: Starts recording a video with the webcam
  - Profile Plot<a id="profile-plot"></a>
    - Location: Bottom right
    - Description: Plot of the profile of the key
  - ID Field<a id="id-field"></a>
    - Location: Bottom right
    - Description: ID of the key

## Technical Explanation (The Pipeline)
### Preprocessing
Image is cropped to a square and resized to the resolution specified by the user in the [Resolution Field](#resolution-field)
### Edge Detection
The image is converted to grayscale. Then a Canny edge detector is used to detect the edges of the key.
### Segmentation
The key is assumed to be the largest object in the image. A mask is created using bwlabel.
### Rotation
Using a hough transform, the angle of the key is calculated. The image is then rotated by that angle.
(The image is sheared by the angle of the key to make the vertical edges line up)
### Mirroring
The image is mirrored to make the the profile face up and left.
### Profiling
The profile is calculated taking the fist non-zero pixel of each column of the mask.
### IDing
The 10 most significant peaks of the profile are used to calculate the ID of the key.

## Contributing
### Reporting Bugs
- If you find a bug, please report it by creating a new issue on the GitHub repository

### Suggesting Enhancements
- If you have an idea for an enhancement, please suggest it by creating a new issue on the GitHub repository