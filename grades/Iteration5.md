# Iteration 5 Evaluation - Group 4

**Evaluator: [Flynn, Michael](mailto:mflynn@jhu.edu)**

## Progress Comments -- on target for iteration 6?

### Size of codebase -- looking reasonable?

* It's looking pretty light, especially for a group of 5 people.

## Code Inspection

### non-CRUD feature code inspection

* Path planning seems fine, but it would be better if you describe exactly how
  your algorithm is working with considering time of day and type of crimes. If
  you can implement a graph representation in your backend that would be
  ideal.

### Package structure of code and other high-level organization aspects

* Looks fine.

### Code inspection for bad smells anti-patterns, etc

* Backend is very data-centric at the moment, you have a bunch of small classes
  that essentially just hold data, and your service class does all of the
  processing.
* It looks like some of your classes still hold properties for the lat/long
  location instead of using the Coordinate class.
* You should be using MVC for your frontend more, especially for doing things
  like drawing overlays.
* Your use of the state pattern is a little weird, it looks like it's
  determining the way the map should look and also doing a bunch of route logic
  as well.

*(-10 points)*


## Build / run / test / deploy

* You were supposed to include instructions on how to build and run your
  project in the README.
* I'm not sure what `build.sh` did, but I think it ran the server in the
  background? Does it produce a build of the iOS app, or just test it?
* How are you deploying your app?

*(-5 points)*

## Github

* It looks like you haven't touched any of your issues since iteration 4.
* You should be integrating into master more often, it appears like you haven't
  accomplished much for this iteration.

*(-5 points)*

## Iteration Plan / Docs

* It looks like a lot to do for the last week.
* Documentation is there, but entries are still not descriptive.

## Misc Feedback

* If you're limiting this just to Baltimore, why don't you zoom the map over
  that location instead of the entire US?
* You may also want to limit searches to Baltimore only, I tried getting
  directions from my home to Hopkins and it found my address in DC.
* I had trouble typing in addresses in the search bar -- it keeps clearing what
  I type.
* It keeps dropping a pin at one of the locations I specify instead of giving
  me directions.

## Overall Comments

It doesn't look like much got done, but I look forward to seeing this finished!

**Grade: 80/100**
