[🇬🇧 English](README.md) • [🇷🇺 Русский](README.ru.md)

# Tap-Dance-for-Windows

Welcome to **Tap-Dance-for-Windows**, your playground for remapping keys and crafting tap-dance magic on Windows.

---

## 🚀 Key Features & Interactions

- **Tap vs. Hold Actions**
  - Assign two distinct behaviors to a single key – one for a quick tap, another for a sustained hold. Perfect for creating dual-role keys.

- **Multipresses**
  - Each press is not just the execution of an assigned action, it is a path to new unique nested assignments. Add an action to any sequence of presses.

- **Infinite depth of nested assignments**
  - Assign actions to any depth: want to use your Space bar to input Morse code? Or add autocorrect for a long word? Each tap can open a new field for assignments to any key, with no length limit.

- **Multi-Key Chords**
  - Define complex chords with any set of keys and map them to any action or sequence.

- **Custom Modifier Keys**
  - Designate any key – including space bar, CapsLock, Q, or any other – as a modifier for assignments and chords.

- **Layered Layouts**
  - Organize your keymaps into “layers” (e.g., base, symbol, media) and switch between them on the fly via hotkeys or GUI controls.

- **Live Management**
  - A lightweight GUI for visualizing, editing and dynamically switching layers, with cross-layer assignment views and individual assignment indicators.

- **Separation of Layouts**
  - Assing specific mappings for individual keyboard layouts that apply only to those layouts, while also combining them with global mappings that are always active.

- **Integration Hooks**
  - Easily call predefined or your own functions on any event. Expand your usage experience with new action types.

- **Fine-tune every press**
  - Set separate actions for press and release, customize hold-catching duration, configure waits for subsequent keys, and specify whether a press is irrevocable or momentary, without breaking transition chains.

---

## 🎮 Usage & Workflow

0. **Clone** this repo.
    - *(optional)* Install AutoHotkey v2.
1. **Run** `main.exe` or `main.ahk`.
    - On initial GUI startup:
      - Press your toggle-layer hotkey to cycle layers.
      - Customize the appearance and behavior of the GUI via 🔧 in the lower right corner.
2. **Try** some of predefined layers.
3. **Define** your own tap/hold and chord behaviors.
4. **Use** new assignments immediately, without restarts.
5. **Add** `main.*` to system startup.


### Prerequisites

- Windows 10 or 11

*(optional)*
- AutoHotkey v2

---

## ⚡ Experimental C Core Engine

For lower latency and more functionality, there is a test reimplementation in C. So far only a working minimum without GUI, customizations, with limitations of system modifiers.

---

## 🖥️ GUI & Detailed Usage

> Alternative description in article format [on Habr](https://habr.com/ru/articles/900000/) (in Russian)

Curious about how it all looks and works? Here’s a friendly walkthrough:

### 🔄 First-Time Launch
1. When you fire up `Tap-Dance-for-Windows` for the very first time, use your normal layout‑switch shortcut (e.g. `Win + Space`) to cycle through *all* active keyboard layouts. This “primes” the engine so it knows which layouts you’ll want to use.
2. Next, keyboard‑shaped GUI will appear, complete with two lists (for layers and chords) and helper buttons. Carefully adjust the appearance and behavior of the GUI via 🔧 in the lower right corner. (Let me know if the window appears oversized)


### 🗺️ Visual Cues & Navigation

#### Tap vs Hold
- Text on the button – tap (above) and hold (below) values, if any. Each assignment can have an its gui name, which will be reflected instead of the value itself.
- Colored border – special type of hold: yellow shows chord components; blue – assigned modifiers; black – currently active GUI modifiers, taken into account for the current assignments to display.
- Additional colored indicators show the changed settings of each assignment – at the top for base assignments, at the bottom for hold assignments. In the right corner, a red indicator or counter (changeable in the settings) shows the number of child transitions. On the left side are indicators for the press settings that have been changed. In order of display:
  - The silver indicator shows that the name for the GUI of the assignment has been changed (to avoid confusion)
  - Gray – a non-returnable assignment has been set
  - Teal – independent activation
  - Blue – additional action on release
  - Purple – modified hold activation time
  - Pink – modified waiting time for the next press for child transitions (only for the next level)

#### Drilling In
Use your physical keys to navigate (both with tap and hold) or just with mouse – left‑click a key (tap) or right‑click (hold) to dive into its next level of mappings. You’ll see the new options listed above the on‑screen keyboard. You can change or clear both tap and hold assignments here.

#### Path Bar
Arrows in the top menu show the path to the current view.
- The arrows indicate the type of transition – ➤ for base press, ▲ for hold, and ▼ for chord. If the arrow is accompanied by a number (e.g. `2➤`), it means that this transition was performed with the corresponding modifier value (it can be either a single modifier or the sum of several values).
- To return to any of the previous levels, click the corresponding button. The modifier value of the transition will be saved. Pressing the current level button again will reset all active modifiers.

### ⌨ Layouts
You can create assignments for a single keyboard layout, or for all of them at once.

#### Layout Selector
Above the arrow keys there is a drop-down list with your layouts, as well as the generic value `Global`, where you can choose which layout to add assignments for. Also, layouts that were found in your layers will be added to this list, even if those layers are inactive (customizable).
> In the GUI you see, for greater control, separate global assignments, and separate assignments for each layout. But when the main script runs, these assignments are mixed – **global assignments are added to each layout**, with priority for specific layouts when cross-assignments are found.

### 🌫️ Layers
The left list displays all `*.json` layers found in `layers\`. Change the checkbox to set the layer activity. To interact with layers use buttons below the list – change its relative priority (it affects how cross-assignments are triggered), edit its name, delete and add new ones.

Double-click on any layer to switch to the mode of its separate viewing and editing, without binding to currently active layers.

Also the layer list displays the assignments along the current path and the number of child transitions from it for each layer, if any – so you always know what is happening at that level on all layers. By default, values from inactive layers are not collected or displayed, for better performance, but you can temporarily change this behavior in the settings.

### 📌 Pre-written layers
There are several layers already hosted in the repository, which you can use to familiarize yourself with the functionalaty before assigning your own:
- **Default**: 83 additional extended-punctuation symbols placed only on the letter part with just one modifier. And an unbreakable space with the second.
- **Controlling Keys**: a new take on the familiar positioning of the control keys. As well as additional media keys, hjkl navigation, and a few everyday functions, like increasing/decreasing the number under the cursor, one-word CAPS, delayed start/stop music, and other trivia.
- **Leader**: a dozen functions under one button. Like a template for your content.
- **Emoji**: how many of them are there?..
- **Extra langs**: yoü use å separate łayout for a couple of ñew letters? There are 12 for each script, and a whole row of global diacritics. Write in any language ø. (*layout đependent*)
- **Numrow Shift**: 0-indexed numrow. If you’re too lazy to make a separate layout for it (I’m like this).
- **Morse code**: you’ve only seen it on TV? You can try it for yourself.
- **Chord test**: just so you’ll try it. It’s no use.
- **NumLock** and **One word caps**: auxiliary layers toggled from other layers via the custom `ToggleLayers` function.
- **Angry**: one of the variants of using the `Instant` option. Don’t swear.
- **…and a lot more of your own?**

### 🎨 Defining first assignments
To add or change an assignment, click on the corresponding key on your keyboard or click on it with the mouse in the interface. After clicking, a menu with the `Base` and `Hold` panels will appear on the top right of the layout. `Base` is responsible for the assignment when pressed, `Hold` – when held. Click on their buttons to enter new assignments.

#### Types of assignments
When assigning a new action, choose its type from the dropdown:
- **Plain Text** – any string you would like to enter. Some unique character, your duty email, cherry pie recipe, whatever you want.
-  **Key Simulation** – commands in AHK-syntax, like `{SC010}` or `+^{Left}`, to simulate certain keystrokes. You can read the syntax in detail on the [AHK website](https://www.autohotkey.com/docs/v2/KeyList.htm).
- **Function call** – any of the existing ones, or your own AHK function, such as `SendCurrentDate` or `ExchRates(USD, RUB)`.
  - Strings go in the box *without* quotes; if your function takes no parameters, you can drop the parentheses entirely.
  - To simplify assignments, basic user functions can be assigned via the auxiliary menu displayed when the corresponding menu item is selected.
- **Disabled** and **Default** – are basic types that may be needed when configuring auxiliary keys in a transition chain.

#### Additional parameters
In addition to selecting the action type and the action value itself, you can also set additional parameters such as:
- Instant activation – makes the assignment independent of child transitions, performing the assigned action immediately upon capture. The chain of transitions is not lost and you can continue diving.
- Irrevocable press – prevents returning to the root from the current press. Normally, the return occurs when the leaf (the last element of the assignment chain) is reached, or when the timer for waiting for the next press (if any) expires. With this option this does not happen, and you remain at the current level if there are no child assignments, or in an unlimited wait for the next press. By default, irrevocable option is offered for all assignments from under modifiers, to allow multiple value entry.
- Modified hold timeout – is the value in ms that will be used to distinguish tap/hold, instead of the globally specified value. **!** This acts exactly on the base assignment. In other words, you tell when the base assignment goes to the hold.
- Modified child press wait time – like the previous one, in ms, replaces global. Works only for one level under the given assignment.
- Additional release action – calls another action of the specified type and value when the key of the catched assignment is released. The action will be recorded at the moment of catching the whole assignment, and will not be broken by any transitions.
- GUI shortname – purely for visually enhancing your layers in the GUI. Useful for almost all assignments except single character texts.

If you’re in edit mode for a specific layer, or if you have only one active layer, the assignment will be automatically linked to it. Otherwise, an additional list is displayed to select the layer to which the assignment will be linked.

> For system modifiers, only modifier-on-hold can be assigned, so they don’t have almost all other fields.

### ✨ How it works

When you press a key, the script checks if there is in the current transition table both base and hold assignments.
  - If there is only the base, it goes into the next check.
  - If there is a hold assignment, the program checks if the key will be held for the specified number of ms.
  - Releasing the checked key before the timer is considered as a basic tap.
  - Holding for the specified time will send the hold assignment to the next check, without linkage to the subsequent key release.

#### Transition
After defining the assignment (tap or hold) it is checked for its own transition table. If it has one and it is not empty, the current transition table is replaced with a new one and the script waits for the next key by specified or global timer value, without executing the current action. If the assignment has the `Instant` option added, the action will be executed immediately and the table will move to the next node in the same way, with a new key waiting.
  - If there is no new keypress for the given timer, the last action will be executed (hereinafter – if not already executed by `Instant`) and the transition table returns to the root table, if the `Irrevocable` option is not specified.
  - If a subsequent catched press (key with defined tap or hold) is not present in the current transition table, the last value is executed and the new press is processed starting from the root.
  - If a catched press is present in the transition table – it starts from the first line of this paragraph (checking the base and hold assignments for the pressed key, …).
> No unnecessary waiting! If there are no hold assignments – base action will be catched immediately. And if there are no nested assignments – action from catched assignment will be executed immediately as well.

#### Return to Start
Every time you reach the last item in the chain (leaf), or if the chain is interrupted by a timer, the table returns to the root state, except in cases of `Irrevocable`.

#### Timer Delay
Special hold types such as `modifier` and `chord part` delay the timer, and while the corresponding keys are held down, table reset and action executing do not occur.

#### No Return Entry
By default no return occurs when entering via `modifier`. As long as the modifier is held down, you can perform any number of keystrokes for the current table, and the return will only occur when the modifier is released.
  - But this doesn’t prevent you from navigating to deeper levels of nesting. The transition, even with the modifier, returns us to the second item in the block (checking a nested table, …).
  - Plus, each transition resets the value of mismatched modifiers, and the timer delay no longer works.

### 📂 Modifiers
Any key can act as a modifier _on hold_. Assign its hold value as a numeric “modifier ID”, that will be used for other assignments. Combined modifier is obtained from the sum of the value of several modifiers (only different).

#### Mod Behavior
Every time you reach the last value in the transition table, you return to the root table. But not in the case of modifiers – presses through them by default keeps you at the current level, allowing you to call any number of assignments along the given path. Even pressing assignments that don’t exist at the level doesn’t reset you. Returning will happen when you release all modifiers. But you can still go to a deeper level if the local assignments have a non-empty transition table, in which case a previously active modifier will no longer serve as a reset protection.

#### Visuals
- Modifier keys get a **blue** border; active mods are **black**.
- To switch the modifier in the GUI, right-click on it or hold the phisical key.
- The modifier value for the help key is displayed directly at bottom of the key (if not overwritten by a gui name).

> Pressing modifiers are not separate transitions with their own tables, they only change a unite value within one transition level, which will be taken into account for other assignments.

### 🎶 Chords
The right list shows chords valid at your current path. Click `New` to enter chord‑selection mode, press or click your desired combination, then assign it just like usual tap/hold value.

> If two chords share a common key combo, both will fire when pressed.

#### Chord nesting
Chords themselves can nest further. You can add assignment under chord, chord under chord, whatever you like. Double-click on a chord line to jump to the nested table.

#### ModChords
Chords work with modifiers, and although mechanically it is one large chord, modifiers are not considered to be keys within it. When you add or edit a chord, the currently assigned modifiers are not selectable.

#### Overrides
A `chord part` is a separate hold type, so when adding/modifying a chord, existing hold values of other types in the keys involved **will be overwritten**.

---

## 🗂️ JSON Layer Format

Layers live in `layers/` as JSON files. Each file is a Map where:

```jsonc
{
  "<LAYOUTID>": [  // "0" for global assignments
    {  // scancodes table
      "<scancode>": {
        "<modifier>": [
          "action_type",             // int (1-7)
          "value",                   // string
          "up_action_type",          // int (1-7)
          "up_value",                // string
          "is_instant",              // bool
          "is_irrevocable",          // bool
          "custom_long_press_time",  // int (0 as default)
          "custom_next_key_time",    // int (0 as default)
          "gui_shortname",           // string (empty to display the assigned value)
          "<nested_map>"  // -> [scancodes{}, chords{}]
        ],
        //...
      },
      //...
    },
    {  // chords table
      "<hex_buffer>": {
        "<modifier>": [
          "action_type",
          // …and all the same structure
          "<nested_map>"  // -> [scancodes{}, chords{}]
        ],
        //...
      },
      //...
    }
  ],
  //...
}
```

---

## 🤝 Contribute

All contributions welcome! Please open issues or PRs for new features or improvements.

The easiest ways to contribute:
- **Layers** – suggest your own unusual, useful, or just amusing uses for the project. It’s always interesting.
- **Functions** – an endless field of suggestions, it can be really anything. But if it’s useful to you, it might be useful to someone else.
- **GUI** – endless edits of pixels and texts that don’t fit. Lots of valuable little things to fix.
- Fix Runglish in readme ^^'
- … and of course you can just spread the word and share the link with your friends, acquaintances, and, maybe, subscribers 👾

> 🚧 The project is under active development and may contain bugs.
> Please report all problems and suggestions in the Issues section.