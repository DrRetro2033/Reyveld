# Arceus

### The modern save manager and editor.

> [!WARNING]
> This is still in alpha.

![Arceus](https://archives.bulbagarden.net/media/upload/thumb/9/9e/0493Arceus.png/900px-0493Arceus.png)

# What is Arceus?

Arceus is a brand-new CLI save manager and editor inspired by version control software like Git. It's designed to provide an easy-to-manage location for your game saves.

# Features

## Branch Off Into Different Timelines 🌌

With Arceus, you can create branches of your saves, so multiple versions of one save can exist simultaneously.

## Rollback to Older Saves 🕔

Arceus allows you to roll back saves to earlier versions, preserving your original save file in case you make a mistake.

## Keep track of YOUR saves 👥

Multiple people can play the same game, even if it’s not designed for switching between different players. Just create a user profile!

## Go Beyond with Add-Ons 📦

Arceus includes Lua (thanks to lua_dardo), enabling you to use it for virtually any game.

> [!NOTE]
> In the future, I plan to add built-in functionality for easier transfer tool creation, similar to Pokémon Bank. For now, you’ll need to build your own transfer tools.

## Built-In Hex Editor #️⃣

Arceus includes a CLI hex editor you can use to edit saves, view changes, and test plugins.

## Tiny Size 📁

Arceus requires no external libraries not already compiled with the app, so it has a small footprint on your computer. And as a bonus—no DLLs to worry about!

## Cross Platform 🖥️📱

Arceus can run on any modern device!

## Developer Friendly 🤝

Any developer can use Arceus in their projects, even you! Just remember to give credit if you incorporate it into your project.
> [!NOTE]
> If you want an example of what you can do with Arceus, check out my other project [MudkiPC](https://github.com/Pokemon-Manager/MudkiPC).

# Want to Try?
Click the badge below to download the latest artifact.

[![Build](https://github.com/DrRetro2033/Arceus/actions/workflows/build.yml/badge.svg)](https://github.com/DrRetro2033/Arceus/actions/workflows/build.yml)

![How to download artifacts.](images/download_archive.GIF)

# Planned Features for the Future

## Frontend GUI 🖱️
Create a frontend for Arceus to make it even simpler to use.

## Save on Close ❌
Whenever you close a game, Arceus will “grow a star,” ensuring you can return to a previous save, even if you forget to use Arceus.

## Cloud Backups ☁️
Transfer your game saves between devices and keep them safe from data loss.

|Planned | Service |
| --- | --- |
| ✅ | Google Drive |
| ✅ | OneDrive |
| ⚠️ | Dropbox |
| ⚠️ | Self-hosted |
| ❌ | iCloud |

# Use Cases

## For Save Editors 📝

The main use case for Arceus is for developers wanting to make a save editor. Arceus can be used in save editors to make it easier to focus on what actually matters, the features.

## For Game Development 💻

Easily roll back to any point in your game for testing, provide items for debugging, or intentionally corrupt a save to test edge cases—without writing debug menus! You could even use Arceus as a backend for saving and loading data in any engine.

## For Multiple Players 🫂

Even if a game doesn’t support multiple saves, Arceus can make it easy for multiple players to maintain their own saves.

## For Achievement Hunting 🏆

Jump to specific points in a game to collect achievements without occupying multiple save slots or using quicksaves.

## For Reverse Engineering 📋

Binary files can be challenging to analyze, but Arceus is designed to detect the smallest changes in a file’s history.

# Why is it called Arceus?

The program is named Arceus because Arceus is the "god" of Pokémon and has the ability to affect time and space. It’s also named in connection to my other project, [MudkiPC](https://github.com/Pokemon-Manager/MudkiPC), which is Pokémon-related.

# Consider Sponsoring ❤️

Consider sponsoring me on GitHub to help support this project! If you can’t, no worries—spreading the word about Arceus is equally appreciated. Thank you!
