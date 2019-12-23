# METEOROIDS

## Synopsis

This is my generic brand recreation of the classic arcade game, Asteroids, rebuilt completely in Godot. It is the first of what I hope will be a long running series called Let's Make! over on my YouTube channel where I will be streaming development of projects like this.

To give myself a little extra challenge, I am once again trying my self coined "Monolith Challenge" that I tried for my game Snek- a recreation of Snake in the Godot Engine. For those of you who aren't familiar, the Godot Engine is a fully functional IDE with a visual editor built in so that you can swap back and forth between coding and crafting your world with ease. A large part of the Godot design philosophy is the use of Nodes which can organize game logic into manageable chunks, much like Objects are used in Object Oriented Programming languages. Usually to create a game world, you can make a well organized tree of Nodes to keep your design sensible and your game running smoothly.

Well, in the Monolith Challenge there is none of that. You get ONE Node and ONE Script for the whole game. That means instead of being able to switch between scenes for your menu and gameplay, you now have to keep track of your gamestate all in one game loop. Everything you do must be done programmatically. You are more than allowed to instance other nodes through the script, but you absolutely must not have anything in the primary game scene other than ONE NODE and ONE SCRIPT by default.

## Why?...

If you are familiar with Godot you are probably wondering... why in the world I would subject myself to this. More or less two reasons:

One, because it is fun. I learned C++ before anything else and I sometimes miss the drugery of having to do everything programmatically, there was just something oddly satisfying by seeing some spaghetti code come to life and work against the odds.

And two, because doing things this way can help you learn features of the engine you might not otherwise ever have much of a reason to use in a normal prototype. Since Asteroids is one of those "Baby's First Clone" games that every gamedev makes some version of at some point (much like Snake, or Pacman, or some others) I feel like the challenge of just making a pure Asteroids clone with all the extra tools Godot gives me might be kind of dull. This way I know it will still be a challenge for me, but more than likely well within the scope of what my skillset can handle. And along the way I hope I can get to learn my favorite game engine a little better.

## Self Promotion

Website https://www.animerrill.com
Itch.io https://animerrill.itch.io/
YouTube https://www.youtube.com/c/EthanMerrillAniMerrill
Twitter https://twitter.com/AniMerrill
Mastodon https://www.toot.site/@animerrill
DeviantART https://www.deviantart.com/animerrill

YouTube Playlist for Let's Make (Coming soon!)
Latest Builds on Itch.io https://animerrill.itch.io/meteoroids
