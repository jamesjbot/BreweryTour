# BreweryTour

What is it?
  -----------

BreweryTour is a Swift based App to help you find breweries that make the style of beer you currently gushing over.
When my friends introduce me to a new style of beer, I've had trouble finding other places that brew that type of beer.
This app solves that problem for others. It allows you to search for all breweries that produce your desired style.

Current capabilities include:

Select a style and all the brewery associated with it will download.

Select a brewery and all the beers associated with it will download.

Search for a brewery by name in the search bar on the Selected Beers / All Beers Tab

Search for a beer by name in the search bar on the Selected Beers Screen

Search for breweries in a specific area (use the map and place a pin in the new area)

On the map you can limiting the amount of search results (use slider on the map to limit the results)

On the map you can target you search results to a specific area by long pressing.

On the map you can favorite a brewery, this will allow you to get driving directions to it in the Favortes Brewery Tab

On the selected beers / all beers tab you can get detailed infromation on the beer by clicking it.

On the beer detail screen you can favorite the beer or save tasting notes.

To get directions to the brewery (first favorite a brewery on the map, then go to the favorite brewery tab and click the brewery)


How to Install?
  -------------
After downloading, please navigate to the folder and type `pod install`

Then go into the folder BreweryTour, open BreweryTour.xcworkspace.

Then build the project.


Technologies Used
  -------------
This data source for the beers and breweries is BreweryDB, http://www.brewerydb.com
The data persistence is achieved mostly thru CoreData, the tutorial states are saved in UserDefaults.
The choice of embedding a TabBarcontroller in a NavigationController was just to challenge myself.
I was trying to learn MVVM Design Pattern so that is all the tablelist and view model stuff you see in the code.
