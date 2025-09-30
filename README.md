<h1 align="center">Reyveld</h1>
<h2 align="center">The modern file toolbox.</h2>
<h3 align="center"><a href="https://drretros-organization.gitbook.io/arceus/">Documentation</a></h3>

> [!WARNING]
> Reyveld is now in beta! However, please always back up your files as a precaution, as there is still a chance of corruption or deletion.

# What is Reyveld?

Reyveld presents you a powerful, fast, and easy to use toolbox with Lua 5.3 as it's scripting lanaguge.

# Features

## Edit Raw Data with Confidence 📜

Easily open binary files to both read and write data with ease!
```lua
function IncrementPK9SpeciesBy1(path)
    local file = SFile.open(path)
    file.set16(0x08, file.getU16()+1)
    file.save()
end
```

## Branch Off Into Different Timelines 🌌

With Reyveld, you can create branches of a folder, so multiple versions can exist simultaneously. So secondary playthroughs (or projects) can branch off from an initial instance, without need to restart from the beginning!

```lua
function Grow(path, starname)
    local skit = SKit.open(path)
    skit.header().getChild({tag=Constellation.tag()}).current().grow(starname)
    skit.save()
end
```

## Rollback to Older Versions 🕔

You can even rollback to earlier versions of a folder or file, preserving any previous actions. So no matter the mistake, Reyveld can help you get back on track.

```lua
function Rollback(path)
    local skit = SKit.open(path)
    local const = skit.header().getChild({tag=Constellation.tag()})
    const.current().back(2).makeCurrent()
    const.sync()
    skit.save()
end
```

## Minimal Boilerplate 🥣

You don't need large, complex logic to modify files, convert data, or create version control from scratch; Reyveld will take care of all that!

## Easy Intergration 🔗

Reyveld can be intergrated with any other application by connecting with WebSocket, which makes it great backend!

> [!NOTE]
> You can still run scripts in Reyveld from the command line, however, it's not recommended.

## Transparent Authorization 🥂

Developers can ask for permissions from their users easily with AuthVeld, an modern, auto-formatting, and detailed authorization form.

## Developer Friendly 🤝

Anyone can use Reyveld in their projects, yes even you! Just remember to give credit if you incorporate it into your project.

## Cross Platform 🖥️📱

Reyveld can run on any modern device that can run Dart code!

# Use Cases

## For Achievement Hunters 🏆

Jump to specific points in a game to make collecting achievements easier, without occupying multiple save slots or using quicksaves.

## For Speedrunners 🏃‍➡️

Reyveld makes it easier to practice routes, find exploits, make a starting point, and keep your personal saves away from your speedrunning attempts.

## For Modders 🛠️

Keep your modded saves away from your main game saves, and recover from a corrupted save with ease.

## For Youtubers 🎥

Ever needed to replay a specific point of a game to get better footage? Well, Reyveld makes it easy and quick to do so.

## For Artists & Video Editors 🎨

Artists can join the fun as well! Simply create a constellation inside a folder, and add the files you would like to track! It's that simple! Reyveld will work with anything; [Krita](https://krita.org/en/), [Blender](https://www.blender.org/), [Kdenlive](https://kdenlive.org/en/), etc...

## For Game Developers 💻

Easily rollback to any point in your game for testing, provide items for debugging, or intentionally corrupt a save to test edge cases—without writing debug menus! You could even use Reyveld as a backend for saving and loading data!

## For Reverse Engineers 📋

Binary files can be challenging to analyze, but Reyveld is designed to detect the smallest changes in a file’s history.

---

# With more to come...

Reyveld is still evolving, so please, feel free to suggest features that you would love to see!

---

# Consider Sponsoring ❤️

Consider sponsoring me on GitHub to help support this project! If you can’t, no worries— spreading the word about Reyveld is equally appreciated. Thank you!