[🇬🇧 English](README.md) • [🇷🇺 Русский](README.ru.md)

# Tap-Dance-for-Windows

Welcome to **Tap-Dance-for-Windows**, your playground for remapping keys and crafting tap-dance magic on Windows.

---

## 🚀 Key Features & Interactions

- **Tap vs. Hold Actions**
  - Assign two distinct behaviors to a single physical key – one for a quick tap, another for a sustained hold. Perfect usage of dual-role keys.

- **Multi-Key Chords**
  - Define complex chords with any set of keys and map them to any action or sequence.

- **Custom Modifier Keys**
  - Designate any key, be it the space bar, CapsLock, Q, or any other key, as a modifier for new assignments and chords.

- **Multipresses**
  - Each press is not just the execution of an assigned action, it is a path to new unique assignments. Add an action to any sequence of taps.

- **Infinite depth of nested assignments**
  - Want to use your Space bar to input Morse code? Or add autocorrect for a long word? Every tap is a new level, and a new field for assignments, with no length limit.

- **Layered Layouts**
  - Organize your keymaps into “layers” (e.g., base, symbol, media) and switch between them on the fly via hotkeys or GUI controls.

- **Live Management**
  - A lightweight GUI for visualizing, editing and dynamic switching layers.

- **Separation of Layouts**
  - Set separated mappings for any keyboard layout, that will only work on these layouts and combine it with global mappings, that will always be active.

- **Integration Hooks**
  - Easily call predefined or your own functions on any events. Expand your usage experience with new action types.

---

## 🎮 Usage & Workflow

0. **Clone** this repo.
1. *(optional)* Install AutoHotkey v2.
2. **Run** `tdfw.exe` or `tdfw.ahk`. On initial GUI startup:
    - Press your toggle-layer hotkey to cycle layers.
    - Use built-in config to set your layout format and key preferences.
3. **Try** some of predefined layers.
4. **Define** your own tap/hold and chord behaviors.
5. **Use** new assignments immediately, without restarts.


### Prerequisites

- Windows 10 or 11

*(optional)*
- AutoHotkey v2
- C Compiler: MinGW-w64 or MSVC

---

## ⚡ Experimental C Core Engine

For lower latency and more functionality, there is a test reimplementation in C. So far only a working minimum without GUI, customizations, with limitations of system modifiers.

It uses `c_test.json` layer generated through the main script.

---

## 🖥️ GUI & Detailed Usage

Curious about how it all looks and works? Here’s a friendly walkthrough:

### 🔄 First-Time Launch
1. When you fire up **tdfw.exe** or **tdfw.ahk** for the very first time, use your normal layout‑switch shortcut (e.g. Win+Space) to cycle through *all* active keyboard layouts. This “primes” the engine so it knows which layouts you’ll want to map.
2. Next, a sleek, keyboard‑shaped GUI will appear, complete with two lists (for layers and chords) and helper buttons. It auto‑scales to fit your screen, but you can tweak the zoom level and switch between “wide” and “square” views using the little gear icon at the bottom‑right. That same menu lets you toggle ANSI vs ISO key shape (hint: tall Enter = ISO, short with extra key beside it = ANSI), and even fine‑tune the hold‑delay when you feel comfortable.


### ✨ How it works
- **Key value**: when you press a key, the script checks if there is a value in the current transition table for pressing and holding it.
  - If there is only the former, it goes into the next check.
  - If there is a hold value, the program checks if the key will be held for the specified number of ms.
  - Releasing the tested key before the timer is considered as a basic tap.
  - Holding for the specified time will send the hold value to the next check, without linkage to the subsequent key release.
- **Transition**: after defining the value (tap or hold) it is checked for its own transition table. If it has one and it is not empty, the current transition table is replaced with a new one and the script waits for the next key by the same timer value, without assigning the current value.
  - If there is no new keypress for the given timer, the last value is executed and the transition table returns to the root table.
  - If a subsequent press is not present in the current transition table, the last value is executed and the new press is processed starting from the root.
  - If a new push is present in the jump table – it starts from the first item in that block.
- **Return to Start**: every time you reach the last item in the chain, or if the chain is interrupted by a timer, the table returns to the root state.
- **Timer Delay**: special hold types such as `modifier` and `chord part` delay the timer, and while the corresponding keys are held down, table reset and value executing do not occur.
- **No Return Entry**: also no return occurs when entering via `modifier`. As long as the modifier is held down, you can perform any number of keystrokes for the current table, and the return will only occur when the modifier is released.
  - But this doesn’t prevent you from navigating to deeper levels of nesting. The transition, even with the modifier, returns us to the second item in the block.
  - Plus, each transition resets the value of the currently active modifiers, and the timer delay no longer works.

It may sound confusing, but in practice it is very easy to understand.

### 🗺️ Visual Cues & Navigation
- **Tap vs Hold**: text on the button - tap and hold values, if any, colored border - type of action on hold, underlined text - there are assignments on the transition from the tap.
- **Drilling In**: use your physical keys to navigate (both with tap and hold) or just with mouse – left‑click a key (tap) or right‑click (hold) to dive into its next level of mappings. You’ll see the new options listed above the on‑screen keyboard. You can change or clear both tap and hold values here.
- **Path Bar**: arrows in the top menu show the path to the current view. The arrows indicate the type of transition – ➤ for base press, ▲ for hold, and ▼ for chord. If the arrow is accompanied by a number (`2➤`), it means that this transition was performed with the corresponding modifier value (it can be either a single modifier or the sum of several values).

### 🎨 Defining Actions
When assigning a new action, choose its type from the dropdown:
1. **Plain Text**: any string you’d like sent literally. Some unique symbol, your duty email, cherry pie recipe, whatever you want.
2. **AHK‑Style Scancodes**: commands like `{SC010}` or `+^{Left}`, to simulate certain presses.
3. **Function Call**: one of the predefined, or your own AHK function, e.g. `SendCurrentDate` or `ExchRates(USD, RUB)`.
  - Strings go in the box *without* quotes; if your function takes no parameters, you can drop the parentheses entirely.

### 📂 Modifiers
- **Fourth type**: any key can act as a modifier on hold. Assign its hold value as a numeric “modifier ID” – the engine sums IDs when you hold multiple.
- **Mod Behavior**: every time you reach the last value in the transition table, you return to the root table. But not in the case of modifiers – presses through them keeps you at the current level, allowing you to call any number of assignments along the given path. Even pressing assignments that don’t exist at the level doesn’t reset you. Returning will happen when you release all modifiers. But you can still go to a deeper level if the local assignments have a non-empty transition table, in which case a previously active modifier will no longer serve as a reset protection.
- **Visuals**: modifier keys get a **blue** border; active mods are **black**. Hold‑held mod value is shown on the key.
- **Levels**: pressing modifiers are not separate transitions with their own tables, they only change a unite value within one level, which will be taken into account for other presses.

### 🎶 Chords
- **List**: the right list shows chords valid at your current path. Click “New” to enter chord‑selection mode, press or click your desired combination, then assign it just like tap value.
- **Chord nesting**: chords themselves can nest further. You can add press under chord, chord under chord, whatever you like. Double-click on a chord line to jump to the nested table.
- **ModChords**: chords work with modifiers, and although mechanically it is one large chord, modifiers are not considered to be keys within it. When you add or edit a chord, the currently assigned modifiers are not selectable.
- **Overlap**: if two chords share a common key combo, both will fire.
- **Overrides**: a `chord part` is a separate hold type, so when adding/modifying a chord, existing hold values of other types in the keys involved will be overwritten.

### 🔍 Layouts & Layers
- **Layout Selector**: above the arrow keys there is a drop-down list with your layouts, as well as the generic value “Global”, where you can choose which layout to add assignments for. Also, layouts that were found in your layers will be added to this list, even if those layers are inactive. ⚠ In the GUI you see, for less confusion, separate global assignments, and separate assignments for each layout. But as the main script runs, these assignments are mixed – global assignments are added to each layout, with priority for specific layouts when cross-assignments are made.
- **Layer List**: the left list displays all `*.json` layers found in `layers\`. Change the checkbox to set the layer’s activity, change its relative priority, add new layers. Double-click on any layer to switch to the mode of its separate viewing and editing, without binding to the currently active layers.
- **Harmonization**: also the layer list displays the destinations along the current path and the number of hops from it for each layer, if any – so you always know what is happening at that level on all layers.

### 📌 Pre-written layers
- **Default**: 83 additional punctuation characters only on the letter part with just one modifier.
- **Controlling Keys**: a new take on a familiar positioning.
- **Leader**: a dozen functions and a whole field of emoji under one button.
- **Extra langs**: yoü use å separate łayout for a couple of ñew letters? There are 12 for each script. Write in any language ø. (*layout đependent*)
- **Numrow Shift**: 0-indexed numrow. If you’re too lazy to make a separate layout for it.
- **Morse**: you’ve only seen it on TV? You can try it for yourself.
- **Chord test**: just so you’ll try it. It’s no use.
- **…and a lot more of your own?**

---

## 🗂️ JSON Layer Format

Layers live in `layers/` as JSON files. Each file is a Map where:

```jsonc
{
  "<LAYOUTID>": {
    "<scancode>": {
      "<modifier>": [            // always come in pairs; even-numbered for base taps and odd for hold
        "action_type",           // send raw text; {ahk-style send}; run func(); use as modifier
        "value",
        "<nested_map>"           // how deep is the rabbit hole?
      ]
    },
    "-1": {                      // chord definitions
      "<hex_buffer>": {          // same struture as <scancode>:{}, only with different keys
        "<modifier>": ["…", "<nested_map>"]
      }
    }
  }
}
```

---

## 🤝 Contribute

All contributions welcome! Please open issues or PRs for new features or improvements.

> 🚧 The project is under active development and may contain bugs.  
> Please report all problems and suggestions in the Issues section.