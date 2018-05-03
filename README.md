# 1000-Pitches

This is a mobile pitch booth app for the 1000 Pitches competition.

#### About 1000 Pitches

1000 Pitches is an annual "pitch competition" that gets students thinking entrepreneurially. Each fall, USC students have the chance to submit a 30-second video pitch in exchange for a free 1000 Pitches T-Shirt. Most students pitch spontaneously after being accosted while walking around campus, enticed by the idea of free stuff. The competition collects over 1000 ideas each Fall, and awards the top ideas with industry connections, mentorship, and other cool prizes.

#### API

Access the API repository that complements this mobile app at https://github.com/gosparksc/1kp-api.

### Setup

Before the app can make calls to the API, two changes need to be made.

First, duplicate the `keys.template.xcconfig` file and add the API's auth token in the appropriate field.

Then, change the API endpoint in `Submission.m`. The variable to change is called `kBaseURL`.
