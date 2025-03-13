<h1 align="center">Arceus</h1>
<h2 align="center">The modern save manager and editor.</h2>
<h3 align="center"><a href="https://drretros-organization.gitbook.io/arceus/">Documentation</a></h3>

> [!CAUTION]
> Arceus is still in a very early state, and might cause corruptions. Please do not use Arceus for important files,
> as it could break them permanently. You are responsible for your own files, so make backups and be cautious when using early versions of this program.
>
> Thank you for reading!

<!-- ![Arceus](https://archives.bulbagarden.net/media/upload/thumb/9/9e/0493Arceus.png/900px-0493Arceus.png) -->

# What is Arceus?

Arceus is a command line application that gives everyday users the power and flexiblity of version control, without the complexly and headaches of using Git or other version control systems. Arceus should be usable for every game, program, and project under the sun! Not just Pokémon!

## Branch Off Into Different Timelines 🌌

```
arceus new const "Pokémon X"
arceus -c "Pokémon X" new star "Route 2"
```

With Arceus, you can create branches of a folder, so multiple versions can exist simultaneously. So secondary playthroughs (or projects) can branch off from a initial instance, without need to restart from the beginning!

## Rollback to Older Versions 🕔

```
arceus -c "Pokémon X" jump back
```

Arceus allows you to rollback saves to earlier versions, preserving your previous actions. So no matter the mistake, Arceus can help you get back on track.

## Keep track of YOUR saves 👥

```
arceus -c "Pokémon X" login
```

Got someone else who wants to join in the fun? Don't worry, Arceus has got you covered. With profiles, multiple people can use the same constellation! So if your family or friends to want to do something on your device (i.e. PC, Steam Deck, Mac, etc.), you can sleep soundly knowing your progress is safe.

## Share your journey 🗺️

Package your history up, and send it off to anyone who also has Arceus, so 100% saves are actually 100%!

## Go Beyond with Add-Ons 📦

Arceus integrates Squirrel, enabling anyone to add new functionality to Arceus. Add-ons make it easy to read and write to files, integrate game launchers like Steam, and so much more!

> [!NOTE]
> In the future, I plan to add built-in functionality for easier transfer tool creation, similar to Pokémon Bank. For now, you’ll need to build your own transfer tools.

## Cross Platform 🖥️📱

Arceus can run on any modern device that can run Dart code!

## Developer Friendly 🤝

Anyone can use Arceus in their projects, yes even you! Just remember to give credit if you incorporate it into your project.

> [!NOTE]
> If you want an example of what you can do with Arceus, check out my other project [MudkiPC](https://github.com/Pokemon-Manager/MudkiPC).

# Use Cases

## For Achievement Hunting 🏆

Jump to specific points in a game to make collecting achievements easier, without occupying multiple save slots or using quicksaves.

## For Speedrunning 🏃‍➡️

Arceus makes it easier to practice routes, find exploits, make a starting point, and keep your personal saves away from your speedrunning attempts.

## For Mods 🛠️

Keep your modded saves away from your main game saves, and recover from a corrupted save.

## For Artists 🎨

Arceus is not just useful for gamers, artists can join the fun as well! Simply create a constellation inside a folder, and add the files you would like to track! It's that simple! Arceus will work with anything; [Krita](https://krita.org/en/), [Blender](https://www.blender.org/), [Godot](https://godotengine.org/), etc...

## For Save Editors 📝

The main use case for Arceus is for developers wanting to make a save editor. Arceus can be used in save editors to make it easier to focus on what actually matters, the features.

## For Game Development 💻

Easily roll back to any point in your game for testing, provide items for debugging, or intentionally corrupt a save to test edge cases—without writing debug menus! You could even use Arceus as a backend for saving and loading data in any engine.

## For Reverse Engineering 📋

Binary files can be challenging to analyze, but Arceus is designed to detect the smallest changes in a file’s history.

# SKits

Arceus uses a brand new file format called SKit. SKit uses both XML and GZip to store everything Arceus could ever need, replacing the use of ZIP files and JSON.

## Blazingly Fast ⚡

SKits are quick to read from disk, with everything essential already at the top of the file.

## Multi-Purpose Containers 🫙

Arceus has already switched to saving settings, stars, constellations, users, addons, and more into SKits.

## Tiny Size 🐁

Using GZip to compress its data down, SKit does not bloat your storage or memory, loading nothing but the bare essentials when reading.

---

# With more to come...

Arceus is still evolving, so please, feel free to suggest features that you would love to see!

---

# Want to Try?

Click the badge below to download the latest artifact.

[![Build](https://github.com/DrRetro2033/Arceus/actions/workflows/build.yml/badge.svg)](https://github.com/DrRetro2033/Arceus/actions/workflows/build.yml)

![How to download artifacts.](images/download_archive.GIF)

> [!WARNING]
> Please keep in mind that Arceus is still in alpha, and it is not
> optimized for files larger than a few megabytes.

# Consider Sponsoring ❤️

Consider sponsoring me on GitHub to help support this project! If you can’t, no worries— spreading the word about Arceus is equally appreciated. Thank you!

---

# Comparison with Other Save Managers:

| Feature                  | Arceus | [GameSave Manager](https://www.gamesave-manager.com/) | [Ludusavi](https://github.com/mtkennerly/ludusavi) |
| ------------------------ | ------ | ----------------------------------------------------- | -------------------------------------------------- |
| Tree Structuring         | ✅     | ❌                                                    | ❌                                                 |
| Multi-User Support       | ✅     | ❌                                                    | ❌                                                 |
| Save Editing             | ✅     | ❌                                                    | ❌                                                 |
| Addon Support            | ✅     | ❌                                                    | ❌                                                 |
| Sharing                  | ✅     | ❌                                                    | ❌                                                 |
| Cloud-Sync               | ❌     | ✅                                                    | ✅                                                 |
| Open-Source              | ✅     | ❌                                                    | ✅                                                 |
| Integration w/ Steam     | ❌     | ✅                                                    | ✅                                                 |
| Integration w/ GOG       | ❌     | ✅                                                    | ✅                                                 |
| Integration w/ Epic      | ❌     | ✅                                                    | ✅                                                 |
| Integration w/ Origin/EA | ❌     | ✅                                                    | ✅                                                 |

# Planned Features for the Future

## Frontend GUI 🖱️

Create a GUI frontend for Arceus to make it even simpler to use.

## Save on Close ❌

Whenever you close a game, Arceus will grow a star from the current, ensuring you can return to a previous save without lifting a finger.

## Cloud Backups ☁️

Transfer your game saves between devices and keep them safe from data loss.

| Planned     | Service      |
| ----------- | ------------ |
| ✅ Yes      | Google Drive |
| ✅ Yes      | OneDrive     |
| ⚠️ Maybe    | Dropbox      |
| ⚠️ Maybe    | Self-hosted  |
| ❌ Unlikely | iCloud       |

# Why does it exist?

Arceus was created to be simple way for regular users to be able to quickly and efficiently backup savedata with more advanced tools. However, it has evolved into a more generalized toolkit for working with files.

# Why is it called Arceus?

The program is named Arceus because Arceus is the "god" of Pokémon and has the ability to affect time and space. It’s also named in connection to my other project, [MudkiPC](https://github.com/Pokemon-Manager/MudkiPC), which is Pokémon-related.
