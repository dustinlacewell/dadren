Overview
========

Dadren is a 2D game library for Nim.

Some of its features are:

- A resource-oriented application framework for all your boilerplate needs
- Your typical 2D game facilities like Sprites, Tilemaps and so on
- A data-driven entity component system for modeling rich game objects

Application Framework
---------------------

The `App` is a central type in Dadren and orchestrates a number of concerns on behalf of the game:

- Creating and managing the window
- Pumping keyboard and other events
- Loading settings and resources
- Operating the main loop

Application Settings
--------------------

The App is initialized with a JSON-formatted settings file which contains all the required startup information such as window resolution and the location of **Resource Packs**.

Resource Packs are also JSON-formatted files. They consist mostly of some meta-data about the Resource Pack itself and also the filenames of actual resources. Once loaded, the App makes the various resources available to game code through associated **Resource Managers**.

Resource Management
-------------------

Dadren features the management of various resource asset types such as textures, fonts and sounds. For each resource type Dadren will load a configured Resource Pack. This Resouce Pack tells Dadren where all of the actual resource assets are located. Typically, each asset will have an associated name that can be used by game code to later request the resource.

Scene Management
----------------

The App controls the main loop of the game but will call functions on the current Scene object each frame. This allows the game code to respond to system events, update game state or render.

By changing the active Scene the game can implement different screens like splash screens, main menus and highscore lists.


Entities and Components
-----------------------

Dadren features a rich entity component system that allows you to create lots of different kinds of objects for your game. By defining and reusing small patterns of data you can avoid designing yourself into a corner. These component combinations can be stored in JSON files allowing the design of your game objects by tools and non-technical users like designers. Components can be combined at run-time to create new entity types on the fly!
