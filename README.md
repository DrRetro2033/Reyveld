<h1 align="center">Reyveld</h1>
<h2 align="center">The modern save manager and editor.</h2>
<h3 align="center"><a href="https://drretros-organization.gitbook.io/arceus/">Documentation</a></h3>

> [!CAUTION]
> Reyveld is still in a very early state, and might cause corruptions. Please do not use Reyveld for important files,
> as it could break them permanently. You are responsible for your own files, so make backups and be cautious when using early versions of this program.
>
> Thank you for reading!

> [!WARNING]
> Please keep in mind that Reyveld is still in alpha, and it is not
> optimized for files larger than a few megabytes.

# What is Reyveld?

Reyveld is a WebSocket based server that uses Lua 5.3 to give developers the power of version control, hex editing, and more packed into a single, portable executable.

```lua
function CreateConstellation(kitPath, name, path)
    local skit = SKit.create(kitPath, { type = SKitType.constellation, override = true })
    local const = Constellation.new(name, path)
    skit.header().addChild(const)
    const.start()
    skit.save()
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

Rollback to earlier versions of a folder or file, preserving any previous actions. So no matter the mistake, Reyveld can help you get back on track.

```lua
function Rollback(path)
    local skit = SKit.open(path)
    local const = skit.header().getChild({tag=Constellation.tag()})
    const.current().back(2).makeCurrent()
    const.sync()
    skit.save()
end
```

## Edit/View Raw Data with Confidence 📜

Easily open binary files to both read and write data with ease!
```lua
function IncrementPK9SpeciesBy1(path)
    local file = SFile.open(path)
    file.set16(0x08, file.getU16()+1)
    file.save()
end
``` 

## Cross Platform 🖥️📱

Reyveld can run on any modern device that can run Dart code!

## Developer Friendly 🤝

Anyone can use Reyveld in their projects, yes even you! Just remember to give credit if you incorporate it into your project.

# Why use Reyveld?

## Quick & Dirty Scripting ✍️

Ever needed to quickly write to a binary file, or build a backup of your project? Reyveld can help without needing to install Python.

## Minimal Boilerplate 🥣

You don't need logic to modify files, convert data, or create version control from scratch; Reyveld will take care of all that!

## Unified Code 🔗

Reyveld scripts can be used in many different projects and be shared others easly, so learning different packages or libraries is not needed!

## Transparent Authorization 🥂

Developers can ask for permissions from their users easily with AuthVeld, an modern, auto-formatting, and detailed authorization form.

> [!NOTE]
> If you want an example of what you can do with Reyveld, check out my other project [MudkiPC](https://github.com/Pokemon-Manager/MudkiPC).

# Use Cases

## For Achievement Hunting 🏆

Jump to specific points in a game to make collecting achievements easier, without occupying multiple save slots or using quicksaves.

## For Speedrunning 🏃‍➡️

Reyveld makes it easier to practice routes, find exploits, make a starting point, and keep your personal saves away from your speedrunning attempts.

## For Mods 🛠️

Keep your modded saves away from your main game saves, and recover from a corrupted save with ease.

## For Video Recording 🎥

Ever needed to replay a specific point of a game to get better footage? Well, Reyveld makes it easy and quick to do so.

## For Artists 🎨

Reyveld is not just useful for gamers or programmers, artists can join the fun as well! Simply create a constellation inside a folder, and add the files you would like to track! It's that simple! Reyveld will work with anything; [Krita](https://krita.org/en/), [Blender](https://www.blender.org/), [Kdenlive](https://kdenlive.org/en/), etc...

## For Game Development 💻

Easily rollback to any point in your game for testing, provide items for debugging, or intentionally corrupt a save to test edge cases—without writing debug menus! You could even use Reyveld as a backend for saving and loading data!

## For Reverse Engineering 📋

Binary files can be challenging to analyze, but Reyveld is designed to detect the smallest changes in a file’s history.

---
# SKits

Reyveld uses a brand new file format called SKit. SKit uses XML, GZip, Fernet, and RSA to store everything Reyveld could ever need in small, secure, and verifiable file format; replacing the need of ZIP files.

## Blazingly Fast ⚡

SKits are quick to read from disk, with everything essential already at the top of the file.

## Tiny Size 🐁

Using GZip to compress its data down, SKits does not bloat your storage or memory, loading nothing but the bare essentials when reading.

## Trustworthy & Safe 🔏

SKits are encrypted and signed by you, and only you. So you can share your SKits with confidence, knowing that no one can inject malicious code into them.

---

# With more to come...

Reyveld is still evolving, so please, feel free to suggest features that you would love to see!

---

# Want to Try?

Click the badge below to download the latest artifact.

[![Build](https://github.com/DrRetro2033/Arceus/actions/workflows/build.yml/badge.svg)](https://github.com/DrRetro2033/Arceus/actions/workflows/build.yml)

![How to download artifacts.](images/download_archive.GIF)

# Consider Sponsoring ❤️

Consider sponsoring me on GitHub to help support this project! If you can’t, no worries— spreading the word about Reyveld is equally appreciated. Thank you!

# Development Q&A

## Why does it exist?

Reyveld was created to be simple way for regular users to be able to quickly and efficiently backup savedata in a git like way. However, it has evolved into a more generalized toolkit for working with binary files.