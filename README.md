
# Aerofilterphone

> This is the final project writeup I presented on December 16th, 2018.

# Inspiration
The inspiration from this project came from the MidiFighter 3D (https://www.midifighter.com/#3D). It’s DJ controller outfitted with arcade buttons that controls effects parameters by waving the controller around you. I thought this was a fun thing to use, however this was expensive, required software to setup, and it wouldn’t be my own idea!

It came time to think of ideas. If only there was a cheap electronic device that everyone has around us at all times, that we could reprogram, for free, and control anything within reach of a wireless connection.

From here, I drew upon my iOS development experience, and decided to make an app that would transform the core idea of the MidiFighter 3D — movement control — into something anybody could use.

# Implementation
The original plan: As you wave an iPhone around you, it controls the pitch of an emitted sound, along with a reverb the farther away you go.
The iPhone has a lot of sensors inside it. Altimeter, barometer, infrared light, ambient light, accelerometer, gyroscope... the list goes on. I figured that this would be a good place to start. Map the gyroscope to some sort of oscillator frequency, and bam. Shouldn’t take too long. By “map”, I mean, if the phone moves away from you, say, 10cm, make it go up a semitone. If you move it to the left, it goes up the scale, and vice-versa if you move it right.

I also needed a way to output sound. I found a very easy to use audio library, AudioKit, and got sound outputting in very little time. Now, I have to measure the distance.

After an incredibly informative presentation on “sensor fusion”, and lots of trial and error, I
learned three things:
1. I need both accelerometer and gyroscope data.
1. I need some kind of filtering function to make the data smooth.
1. This data is impossible to get accurately.

The first point was easy enough after some digging on Apple’s documentation. I ignored the second point as the realization from point #3 set in. The data was just too difficult to work with, and after a few days of painful debugging, results were bleak.

Undeterred, I tried to use iBeacons — bluetooth transmitters that gave signal strength values. Their sample rate was restricted to 1Hz by default, which I assumed could be changed in the API. They couldn’t. So, I dug a bit deeper into the CoreBluetooth API to interface with the transmitters directly. After getting the RSSI value, the data was all over the place, and basically unusable for basic detection, never mind calculating distance. I scoured multiple research papers to try to find a way to filter the data (namely using a Kalman filter) and calculate distance from this new data. Still, nothing worked.

After many hours of debugging (not even counting attempts to integrate OSC, SuperCollider, or output sound over AirPlay), I scrapped what I had and made a compromise.


# Final Product
My compromise was to use accelerometer data alone.

When you flick the phone to the left or right, it would read which direction it moved, and change which note was being output. This was hardcoded to the A major scale, and frequency values were assigned within a range to allow for some variability between the notes.

Sometimes, the accelerometer value would be just beyond the boundary, causing for a note to be skipped, or not register. This will be important later.
This also would have been transmitted wirelessly, using the Mac as a sound generator and the iPhone as a controller, if the WiFi wasn’t being as unpredictable as WiFi usually is.


# The Piece
I chose my Timbre piece to play behind the iPhone.

From day one, it was the most fitting option. It gave an extra dimension to the sound being played, and also presented a unique dichotomy between medium and, well... timbre. The contrast of the droning E from violins, violas, cellos, and brass, to a scale sung out of the 3.5mm jack speaks for itself.

There is also a deeper theme here, that I spoke of before the performance — ambiguity.

When you record an orchestra, you can almost always envision the recording space. You can picture a violinist bowing, you can see the conductor waving their arms around, and you can even figure out if the cellos are on the left instead of the right.

However, with the iPhone, that changes. All sound was “flattened”, and on an audio recording, you can’t see the performer waving the iPhone around to produce the different classes of pitch. For all they know, there was only MIDI keyboard on the stage alongside a bad pianist. The code also wasn’t perfect, so sometimes notes would not register properly, which gave a more literal interpretation of “ambiguity” in the form of aleatoric procedures. During the performance, I unintentionally discovered new, interesting harmonies that I otherwise wouldn’t have chosen to play.

My timbre piece also included moments of silence that I was sometimes prepared for, sometimes not. The improvisation was entirely built upon harmonies I imagined as the piece was playing, much like how one writes counterpoint off of a cantus firmus.

Overall — The iPhone’s unique expression of space, as well as contrast in both timbre and technology, makes my instrument more than just a few bits of code thrown together. It, much like the infamous MoPhO project, makes us look at the things we have and realize that there is always something we don’t know. From this uncertainty we can create new things — here, new music — and inspire more music to be made.
