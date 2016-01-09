Overview
========

Dadren is a sprite-based top-down turn-based data-driven survival game engine.

Core Infrastructure Features
----------------------------

**Configurable tilesets:**

Custom tilesets allow for the rehauling of the game's graphical look

**Procedurally generated world:**

Algorithmically generated world for high variance and replayability

**JSON driven entity components:**

Data driven content allows for rapid creation and player modification

Environment Featues
-------------------

**Advanced World-generation:**

Using blended noise complex biomes can be created.

**Procedurally colored tile variants:**

Recoloring tiles at runtime for seasonal and other effects

**Global illumination and point lighting:**

Utilizing sprite tinting to achieve 2D lighting effects

**Day cycle:**

A diurnal cycle that has graphical and gameplay consequences

**Seasonal cycle**

A seasonable cycle that has graphical and gameplay consequences


Item Dynamics
-------------
**Physicality:**

Items have weight and volume and potentially other physical properties

**Composites:**

Many items are composed of two or more combined items

**Deconstructable:**

Many composites are able to be deconstructed into their constitutent parts

**Smashing:**

Bashables and slicables can be deconstructed with physical attacks

**Basic Materials:**

Items which cannot be crafted from other items are basic materials

**Containers:**

Some items are able to contain other items based on relative volume and capacity

**Obstacles:**

Some items prevent movement and the placement of items

**Surfaces:**

Some obstacles are able to support other items on the same tile

**Quality:**

Most items have a quality which determines its general effectiveness

**Durability:**

Expiration of item durability leads to deconstruction or complete destruction


Competence and Parametric Skills
--------------------------------
**Categorical Actions:**

Any action performable in the world belongs to some skill category

**Categorical Competence:**

A base categorical Competence determines a base bonus for associated actions

**Parametric Skills:**

Skills are specific and grant bonuses based on specific item types involved


Crafting Features
-----------------
**Basic materials based crafting:**

Combining multiple materials allows for the production of goods

**Item deconstruction:**

The ability to deconstruct items into constituent materials

**Item customizations and modifications:**

Perform modifications that change items without changing the base type

**Materials and Craftmanship variance:**

Skill and materials and morale directly correlate to production quality


Health and Morale
-----------------
**Basic Needs:**

Hunger, thirst and morale are constant upkeep factors

**Physiology modeling:**

Condition of body parts and their related tissues and bones are tracked

**Immunology modeling:**

Disease and afflictions can have stat and gameplay related effects

**Morale effects:**

The efficency of actions and the quality of crafting is affected by morale

**Satisfaction:**

The efficiency of actions and the quality of crafting can affect morale


Clothing and Armor
------------------

**Area Clothing:**

Clothing and armor types are fitted and worn on specific areas of the body

**Multi-area Clothing:**

Some clothing is worn on multiple areas at once

**Coverage and Warmth:**

Different clothing provides varying levels of coverage and warmth

**Encumberance:**

Different clothing provides varying levels of encumberance to body parts

**Action Effects:**

Actions relying on specific body parts may be effected by clothing encumberance

**Layering:**

Multiple items may be worn on the same area for combined effects and encumberance

**Fitting and Modifications:**

Items may undergo fitting and other modifications to change their properties

**Stateful Clothing:**

Some clothing can have various settings and states such as a mask with a visor


Flora
-----

**Biome specificity:**

Certain plants grow in certain biomes

**Growth Modeling:**

Plants grow and develop overtime changing their look and characteristics

**Seasonal Variance:**

Plants may exhibit various properties during specific seasons

**Non-deconstructable Smashables:**

Plants can be smashed for materials but not deconstructed (they can't be picked up)

**Hardiness:**

A plant's hardiness determines the difficulty in smashing (slashing or bashing) it

**Flowering:**

Plants may flower during specific seasons allowing for harvest of unique materials

**Harvestable:**

Some plants may be harvestable for specific materials without smashing

**Plantable:**

Plants that produce seeds may be planted and if treated will grow as normal


Fauna
-----

**Biome specificity:**

Certain creatures appear in certain biomes

**Seasonal Variance:**

Certain creatures may only appear during certain seasons

**Behavioral State-machine:**

Creature behavior is driven by a graph of states and transitions


