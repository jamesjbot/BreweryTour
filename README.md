# BreweryTour

## Overview
BreweryTour is a Swift based App to help you find breweries that make the style of beer you're currently excited about.
When my friends introduce me to a new style of beer, I've had trouble finding other places that brew that type of beer.
This app solves that problem for others. It allows you to search for all breweries that produce your desired style.

## Technologies Used

UIKit, MapKit, CoreData, GCD, CoreAnimation, CoreLocation, Cocoapods, Generics, Design Patterns.

This data source for the beers and breweries is BreweryDB, http://www.brewerydb.com.  
The data persistence is achieved mostly thru CoreData, the tutorial states are saved in UserDefaults.
The choice of embedding a TabBarcontroller in a NavigationController was just to challenge myself. 
I was learning MVVM Design Pattern, that is the origin of view model stuff you see in the code.
Grand central dispatch is used generously throughout the download process.
Cocoapods was used to integrate AlamoFire Networking.

## Example usage

Upon opening the app, you will be greeted with a tutorial screen click next to see the usage for the screen, click dismiss to dismiss the tutorial.   
You will be on the Style/Brewery selection screen.   
Select a beer style and then it will begin to download all the entries for the at style.
There are alot of breweries and beers per style, the spinner will keep going as long as there are entries to be processed.
Click Breweries with style to see the breweries that have that style.
Click Map in the upper right corner to proceed to mapping all the breweies of your selected style.
You will see a beer mug for every brewery that was returned.
Clicking on the beer will bring up the brewery's name.
If the brewery has a website listed below, clicking on it will bring up the brewery's website.
Click the heart you can favorite the brewery and further on in the app get turn by turn directions to the brewery.
You can control the number of breweries being shown by dragging the slider at the top. 
The number of breweries will be listed on the right side of the slider.
If you click the plus button you have some map options, to show all nearby local breweries, and turn off the green line routing information you see when a brewery is clicked.
At the bottom of the screen is the tabbar that controls views of the map, the beers that you selected via styles/brewery, your favorite beers, and your favorite breweries.
In selected beers tab, you may see detailed information about beers, favorite those beers and write tasting notes.
Favorite beers and Favorite breweries will show your favorites.
In the favorite breweries, clicking on a brewery will bring you to the native map routing app.
So this app is a great way to keep a list of breweries you want to visit in the near future.

Current capabilities include:

* Select a style and all the breweries associated with it will download.
* Select a brewery and all the beers associated with it will download.
* Search for a brewery by name in the search bar on the Selected Beers / All Beers Tab
* Search for a beer by name in the search bar on the Selected Beers Screen
* On the map you can limiting the amount of search results (use slider on the map to limit the results)
* Limit breweries to a specific area instead of your current location (use the map and place a pin in the new area)
* There is a new menu bar on the map press + to access it
* You can now see local breweries relative to your location or the new pin (use the map and tap + menu in the upper right, flip switch for Show all local)
* You can turn off any further routing by fliping the enable routing switch to off.
* On the map you can target your search results to a specific area by long pressing.
* On the map you can favorite a brewery, this will allow you to get driving directions to it in the Favortes Brewery Tab
* On the selected beers / all beers tab you can get detailed infromation on the beer by clicking it.
* On the beer detail screen you can favorite the beer or save tasting notes.
* To get directions to the brewery (first favorite a brewery on the map, then go to the favorite brewery tab and click the brewery)  
* On the beer detail screen you can favorite a certain beer and add your own tasting notes.

## How to set up the dev environment
First have cocoapods installed, if you don't have it there are instructions at https://cocoapods.org

Go to https://github.com/jamesjbot/BreweryTour and download the zip file

After downloading, please navigate to the BreweryTour folder and type `pod install`

Then go into the folder BreweryTour, open BreweryTour.xcworkspace.

Or

From terminal (with git installed), type 
```
git clone https://github.com/jamesjbot/BreweryTour.git
cd BreweryTour
pod install
open BreweryTour.xcworkspace
```

Then build the project.

## How to ship a change
Changes are not accepted at this time

## Know bugs
The ability to search for local beers only works in the United States.
Prior to establishing your current location via gps, the app will default to the center of the United States.
 
## Change log 
* 10-02-2016 Initial Commit

## License and author info
All rights reserved
Author: jongs.j@gmail.com
