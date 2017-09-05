# Camera Camera

## Overview

Camera Camera is a Swift based QR code reading app.

## Technologies Used

UIKit, ReactiveKit, Bond, SwiftyBeaver Logging , GCD, AVFoundation, Cocoapods, Generics, MVVM, Protocol Oriented Programming.   

MVVM design pattern was used to seperate out the layers.      

## Example usage
  
After the app starts up, point the camera at some qr codes.    
The qr codes will be outlined and stay solidly on the screen till you move away, no flickering of the outline will occur.     
At the bottom you can take a photo of the qr codes and it will automatically save to the Photo Album.      
Above the 'Take Photo' button you can deselect qr code overlays in the saved imade.   

Current capabilities include:

* You can see multiple qr codes with the same message payload.   
* You can take a picture with or without qr codes displayed.    
* The app works in all orientations.    

## How to set up the dev environment

First have cocoapods installed, if you don't have it there are instructions at https://cocoapods.org

Go to https://github.com/jamesjbot/Cameracamera.git and download the zip file

After downloading, please navigate to the Cameracamera folder and type `pod install`

Then go into the folder Cameracamera, open Cameracamera.xcworkspace.

Or

From terminal (with git installed), type 
```
git clone https://github.com/jamesjbot/Cameracamera.git
cd Cameracamera
pod install
open Cameracamera.xcworkspace
```

Then build the project.

## How to ship a change
Changes are not accepted at this time

## Know bugs
None
 
## Change log
* 05-09-2017 Initial Commit

## License and author info
All rights reserved
Author: jongs.j@gmail.com
