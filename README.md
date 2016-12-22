2016 Group 4
============
[![Build Status](https://travis-ci.com/jhu-oose/2016-group-4.svg?token=Tf3c7Gfbp6sM6spBqpry&branch=master)](https://travis-ci.com/jhu-oose/2016-group-4)

Survival Maps App
-----------------
[Survival Maps App](https://github.com/jhu-oose/2016-group-4/tree/master/SurvivalApp) is a navigation app which avoids dangerous routes.

[Documentation](https://jhu-oose.github.io/2016-group-4/jazzy/)

Website (Mirrors)
-----------------
[Heroku App](https://oose-survival.herokuapp.com)

[Github Pages](https://jhu-oose.github.io/2016-group-4/site/)

Server
------
[Server](https://github.com/jhu-oose/2016-group-4/tree/master/Server) hosts crime data for use in Survival app.

[Documentation](https://jhu-oose.github.io/2016-group-4/Javadoc/)

Crime Data Processing
---------------------
[Crime Data Processing](https://github.com/jhu-oose/2016-group-4/tree/master/CrimeDataProcessing) preprocesses large datasets for our server.


Build Instructions
---------------------

Build.sh 

What build.sh does: Builds and tests both the front end and back end of the whole project
To run -- Run the .sh file 

Can be run via xcode 

Heroku
---------------------

The app can be run on Heroku through the simple heroku open command in the Server folder which runs and maintains the database. 

Heroku Login Details (for programmer):
Username: nkulkarni248@gmail.com
Password: 2jjqcXg8yiAf


Description of Algorithm (Routing)
-------------------------
[Pre-processing] Send crime dot latitude and longitude coordinates to MapQuest, MapQuest returns coordinates’ linkID
Only consider crimes outdoor
Note: Each crime dot has a corresponding linkID
[Pre-processing] Crime points weighted by type (violent and nonviolent) and by date (older ones have lesser weight)
Crime Type:
Violent: Agg. assault, common assault, homicide, rape, shooting, robbery - street
Non-Violent: assault by threat, robbery (commercial, residential), theft
Date - only use crime points within the past month
[On query] Grouped linkIDs ranked relative worst to best (calculating weighted score of linkID group to determine which is best/worst)
Crime occurring within +/- 3 hours are weighted more heavily than crime at other times
Send linkIDs to avoid to MapQuest

Description of Algorithm (Heat Map)
-------------------------
Add number of crime per pixel 
Using Gaussian sampling distribution with radius of 3 and inverse proportional function, algorithm determines darkness of pixel

Note: radius of 3 keeps optimal time performance in map generation 
Darker pixel density corresponds to higher crime density


Graph Representation 
----------------------
We looked further into doing map backend processing and walked through some implementations of doing this, talking through the design of what this might look like (e.g. representing it as a graph and using some sort of graph search algorithm to do a path planning). That being said, we're still having trouble getting the intersections themselves (vertices), which would be the nodes of the graph. If there's a way to work around that, it's totally a possibility.






