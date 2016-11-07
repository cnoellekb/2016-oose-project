# Iteration 3 Evaluation - Group 4

**Evaluator: [Flynn, Michael](mailto:mflynn@jhu.edu)**


## Positive Points:

* The new projects feature on GitHub looks nice! Looks like you're making
  progress with it.
* Hooray UI tests!
* It looks like you have a clear idea how you're going to see this through to
  the end.


## Suggestions:

### Be cautious about the light server

I get your rationale for not doing a lot of server-side processing for finding
routes, but be careful about what kinds of assumptions you're making and think
about edge cases. Oftentimes I've gotten map directions that were not a
straight line between the two points, so I'd effectively go around the
rectangular area you're querying.

Also, think about scale. Let's say you expand this app to include the entire
United States. What happens if I query for directions from Seattle to Miami?
Are you going to dump your entire database?

If it's a limitation with MapQuest that's fine, but don't let it limit your
app.

## Overall:

So far so good! Keep it up.

** Grade: 100/100 **

