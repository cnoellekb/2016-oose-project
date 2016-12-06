# Iteration 4 Evaluation - Group 4

**Evaluator: [Flynn, Michael](mailto:mflynn@jhu.edu)**

## Positive Points

* Looking good so far, heat map looks cool

## Needs work issues

* Avoid doing a lot of small commits to master with undescriptive messages
* How are you integrating data collection into your app? Are you just running
  your preprocessing script occasionally?

## Code

Looks fine, you don't seem to have much going on in the way of OO design :(

## Tests

Don't make requests to thrid-party APIs in your tests, they shouldn't fail just
because MapQuest is down or is limiting the number of requests you can make --
that defeats the purpose of having tests (i.e. telling you whether or not your
code works)

*(-5 points)*

###  Good code coverage?

Looks fine.

### Travis works?

Seems to be

*(+5 points)*

## Build / run / deploy

`build.sh` works-ish

### Clear scripts for both build/run and deploy?

Please provide instructions in your README about how to build and run
specifically, pretend someone who doesn't know anything has to try to use your
code. Also provide details about how you're deploying to Heroku.

*(-3 points)*

### Grader could fire up and run project?

Yep!

## Github

### Good use of git branch?

Make sure you're being consistent about how you're using branches and have a
process in for it. Avoid doing a lot of small changes on master and using
undescriptive messages as well. Generally master should stay stable.

*(-2 points)*

## Iteration Plan

Sounds good.

## Code Docs

Looks good, but you may want to be a bit more descriptive in some of your
entries.

## Overall Comments

Looks like it's coming along!

**Grade: 95/100**
