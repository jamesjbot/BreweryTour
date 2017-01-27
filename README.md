# BreweryTour
## What is it?
---
BreweryTour is a Swift based App to help you find breweries that make the style of beer you're currently excited about.
When my friends introduce me to a new style of beer, I've had trouble finding other places that brew that type of beer.
This app solves that problem for others. It allows you to search for all breweries that produce your desired style.

---
### How to Install?
---
 
Go to https://github.com/jamesjbot/BreweryTour and download the zip file

Or

From terminal (with git installed), type git clone https://github.com/jamesjbot/BreweryTour.git

Have cocoapods installed, if you don't have it there are instructions at https://cocoapods.org

After downloading, please navigate to the BreweryTour folder and type `pod install`

Then go into the folder BreweryTour, open BreweryTour.xcworkspace.

Then build the project.


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

* On the map you can target you search results to a specific area by long pressing.

* On the map you can favorite a brewery, this will allow you to get driving directions to it in the Favortes Brewery Tab

* On the selected beers / all beers tab you can get detailed infromation on the beer by clicking it.

* On the beer detail screen you can favorite the beer or save tasting notes.

* To get directions to the brewery (first favorite a brewery on the map, then go to the favorite brewery tab and click the brewery)  



---
### Technologies Used
---
  
This data source for the beers and breweries is BreweryDB, http://www.brewerydb.com

The data persistence is achieved mostly thru CoreData, the tutorial states are saved in UserDefaults.

The choice of embedding a TabBarcontroller in a NavigationController was just to challenge myself.

I was trying to learn MVVM Design Pattern so that is all the tablelist and view model stuff you see in the code.

Grand central dispatch is used generously throughout the download process.

Used Cocoapods to integrate AlamoFire Networking


---
#### Know bugs
The ability to search for local beers only works in the United States.
