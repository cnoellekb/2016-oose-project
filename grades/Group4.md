# Iteration 1 Evaluation - Group 4

**Evaluator: [Flynn, Michael](mailto:mflynn@jhu.edu)**


## Positive Points:

* Very useful app idea. Will be very interested to see your final product.


## Things to Improve:

### How does the map get updated?

One major point you seemed to have left out is how your maps are being updated
with crime data. Are you going to give police access to your app to post data?
(In which case, they're another actor) Are the administrators supposed to
manage this? Is this crowdsourced? Are you scraping data? You should specify
this up front, since the first three need use cases and UI for, while the last
one you're going to need to describe how that process is going to work.

*(-2 points)*

### Use cases should be broken up

Your use cases are a little bulky, and they can be broken up more. They should
be much more granular with some high-level behind-the-scenes technical details
that need to happen, e.g. login process, user turns off push notifications,
etc. You can definitely break up your main navigation use case into different
cases for different situations, like "User launches navigation", "User goes off
of path", "User heads into a high-crime area", etc. You might want to specify
alternate paths for these as well.

*(-8 points)*

### No technology in your architecture

You need to specify what frontend/backend/database/APIs/tools you're using in
your architecture section! I wouldn't know it was iOS if you didn't mention it
elsewhere or if your UIs weren't iOS. What map API are you using? Do you know
that it can do everything that you want it to, including voice and being able
to create custom routes? (I guess you're using MapQuest, since it's in your
diagrams) This is *very* important.

*(-6 points)*


## Suggestions:

### Prototype Early!

I mentioned this to you all in lab, but make sure that the MapQuest API can do
everything you want it to ahead of time! You mentioned that you think it can,
but please start prototyping earlier rather than later to avoid figuring out
that you can't do everything you want when the semester ends.


## Overall:

Great start! There are a few holes in your design for this iteration, but
nothing that can't be cleaned up easily. Make sure that this project is
feasible earlier rather than later, but otherwise it should be interesting to
see how it's developed!

** Grade: 84/100 **

