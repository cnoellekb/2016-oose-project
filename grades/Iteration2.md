# Iteration 2 Evaluation - Group 4

**Evaluator: [Flynn, Michael](mailto:mflynn@jhu.edu)**


## Positive Points:

* Overall a good amount of detail, use cases and architecture are much improved
  over the last iteration.
* It's great that you split up your UML for both the front and back ends. The
  iOS SDK is pretty well designed, you'll notice a lot of design patterns when
  we get into that later in the course.


## Things to Improve:

### Back End UML is a little light

There are many more classes that you could represent in your backend, and right
now it seems a little light. Some things I noticed:

* LinkIdsToAvoid is a little confusing. Are these supposed to represent IDs to
  map links in your database or on MapQuest? You might want to model more data
  on this as well to make it easier to query and play with (geolocation, etc.)
* How are you representing the map and routes in your backend? I don't see how
  you can efficiently query points to avoid just given two geolocations, it
  would be better if you built a graph representing the map and traverse that
  to see if you encounter any high-crime areas.
* CrimeDataPoints is wayyy too separated from classes that need to access it.
  Generally you don't have a database class that you have to "reach through"
  for all of your objects. CrimeDataPoints should be a composition for some
  larger class (like a Map model, or something similar).

*(-10 points)*

### Be more general with your REST API

You have your REST API documented, but it has example data instead of
types or descriptions. Give a more general form for your APIs, as if you were
writng documentation for someone else to use.


## Suggestions:

### When is an area considered "safe?"

I'm assuming that when crime is reported somewhere that it doesn't stick there
forever. You're going to want to date your crime reports and consider that when
you're creating routes for users. If you represent the map as a graph, you
could even represent the age of a crime as edge weights and use a shortest path
algorithm.

### Generally, think a bit more about how you're representing maps

I mentioned this in the UML feedback, but you should give more thought into how
you're representing the map, routes, and crimes within your app. As I see it
now, it looks like it's going to be difficult to actually query crimes
efficiently and build your routes. (Unless you're letting MapQuest do all of
the heavy work for you, but then I'm not sure if this project is going to fly
for this course in that case...)


## Overall:

Looks like it's coming along, but make sure you're thinking about how to
represent everything in your back end as well as your front end.

** Grade: 90/100 **


## Iteration 1 Update:

* Map updating explained (+1)
* Use cases updated (+4)
* Architecture updated (+3)

** Reclaimed: 8 points **

