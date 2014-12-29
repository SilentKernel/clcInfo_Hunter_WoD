ClcInfo Hunter WoD Edition
==================

Original WoW Addon : http://www.curse.com/addons/wow/clcinfo_hunter

What is this ?
==============

CLC Hunter WoD edition is based on the addon of link above (wich is under BSD License), the original author stopped the devellopement of his addon at the launch of Warlords.
This version run on WoD and is wrote to use proc / perks form this extension. it still in devellopement but it currently work for survival spec (no with all talent at the moment).

What change from the original version
==========================================

General :
* Won't crash at loading anymore (LUA error Blah Blah)
* Boss detection system totally changed (the new is basic but it run well :D)
* Modified focus cost of spell to the rights values (WoD Values)
* Fixed Barrage talent detection (What is wrong with bilzz's API ??????)
* Added IconHunter1 and IconHunter2 regardless of hunter's spec

Survival : 
* Now support "Thrill of the hunt"
* Moved rotation to make it be the same as http://simulationcraft.org (in progress)

MarksmanShip :
* This spec no longer generate LUA errror eveytime
* Support of Kill Shot WoD Perks (usable at 35% health insted of 20%)

Beast Master :
* Nothing changed at the moment, but spec currently work (will update it when i will make a BM spec for my own hunter)

How to use it ?
===============

*You need CLCInfo installed : http://www.curse.com/addons/wow/clctracker
* Check this video to understand how CLCInfo work : https://www.youtube.com/watch?v=m99Txu4URMk (this is for retribution but don't care, juste see how CLCInfo work)
* Click on download zip on github, unzip it and remove the "-master" form folder's name then addd it to you WoW's addon directory

* Go to CLCInfo, create icon and in the code section put the same as below :
- "return IconHunter1()" without the "" for the current skill button (wich will show you what to do now)
- "return IconHunter2()" without the "" for the next skill button (wich will show you what you do in the next GCD)

