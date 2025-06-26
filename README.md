[🇬🇧 English](README.md) • [🇷🇺 Русский](README.ru.md)

# Tap-Dance-for-Windows

Welcome to **Tap-Dance-for-Windows** — an interactive playground for adding hundreds of single assignments and their chains, of any type for any events. No firmware, drivers, or special hardware required — works with any keyboard and mouse.

---

## 🚀 Key Features & Interactions

> The examples are made up for illustrative purposes; any similarities are purely coincidental. Examples of real-life assignment scenarios are provided in the layer descriptions. You are free to change, add, remove, any assignments and use only those features that you need.

### **> Tap vs Hold**  
The basic events of any key/button, the branching of which opens up a myriad of chains for assignments. Assign two behaviors to the key – one for a quick press, the second for a short hold.  
`x (tap) 🡒 x [default]`  
`x (hold) 🡒 @`

### **> Multipresses**  
Each click is not just the execution of an assigned action, it is a path to new unique nested assignments. Add an action to any sequence of events.  
`Backspase 🡒 Backspace [default]`  
`Backspace, Backspace 🡒 Ctrl+Backspace [delete word]`  
`Backspace, Enter 🡒 Shift+Home, Backspace [delete before the beginning of the line]`  

Expands by branching on hold at any level.  
`Backspace, Enter (hold) 🡒 Shift+End, Backspace [delete to the end of the line]`  
`Backspace (hold), Enter 🡒 End, Shift+Home, Backspace [clear the line]`  
`Backspace (hold), Enter (hold) 🡒 Ctrl+Right, Ctrl+Backspace [delete the following line]`

### **> Unlimited nesting**  
Assign actions at any depth: whether it’s Morse code or auto-correction of words. Each press is a new level and a new field for assignments for all keys, with no length restrictions.  
`Space (tap), Space (tap), Space (tap), Space (hold) 🡒 v`  
`Space (tap), Space (hold), Space (hold), Space (tap) 🡒 p`  
…  
`d, a, m, n 🡒 🤬`  
`s, o, Space, l, o, n, g, Space, s, t, r, i, n, g 🡒 👌`

### **> Custom modifier keys**  
Any key can also be assigned as a modifier for new assignments, whether it be Alt, Space, side mouse button, CapsLock, or any other key.  
`Alt+h 🡒 Left`, `Alt+j 🡒 Down`, …  
`Shift+Backspace 🡒 Delete`  

`\+e 🡒 "example@gmail.com"`  
`\+d 🡒 ƒ Insert the current date`  
`\+d (hold) 🡒 ƒ Insert the current datetime`  

`MouseXButton1+WheelUp 🡒 VolumeUp`  
`MouseXButton2+WheelUp 🡒 NextTab [browser, editor, …]`  
`MouseXButton2+LBM 🡒 Copy`  
`MouseXButton2+LBM (hold) 🡒 ƒ Copy the link and convert it into a short tinyurl`

Any combination of modifiers also has its own fields for assignments!  
`Alt+Shift+h 🡒 Shift+Left`  
`\+Alt+e 🡒 ƒ Generate a random password`  
`XButton1+XButton2+WheelUp 🡒 Ctrl+z [Redo]`

### **> Chords**  
Create complex chords from any set of keys and assign any actions and functions to them.  
`l+o+r+e 🡒 "Lorem ipsum dolor sit amet, consectetur adipiscing elit..."`  
`\[mod] + chord(q+w+e) 🡒 "abcdefghijklmnopqrstuvwxyz"`

Chords, like all other events, can also have nested assignments, including new nested chords.  
`q+w+e, a+s+d, a+s+d 🡒 ƒ Perevod s translita`

### **> Fine-tuning of each event and assignment**  
Add an additional action to any assignment when a key is released, set the hold time or the wait time for the next event, specify the type of irrevocable press or instant activation without interrupting the chain.  

Each event can be assigned any action, from simply entering a single character or simulating another key, to functions that call external APIs, the list of which is regularly updated.  

> You can also add your own functions or simply suggest an idea for implementation.

### **> … and all of this simultaneously, at all levels of the assignment chain**  
`Shift[mod] + Space (tap), MouseXButton1[mod] + chord(a+s+d+f), WheelUp, Esc (hold), F23 (tap) 🡒 "mysupersecretpassword"`

Each level of each sequence is assigned independently of the others, and a single key can simultaneously be a modifier, part of a chord, and have its own events and transitions. Each new level is a new, clean field for assignments.  
`\[mod]+e, \ (tap), \ (hold), chord(\+z+x) 🡒 ƒ Turn on the Pomodoro timer`

### **> Any keys and buttons**  
All keys are supported – an additional row of multimedia/office keys, virtually assigned f13-24, and all mouse events, right up to horizontal scrolling.  

> The additional multimedia-office row and mouse scroll do not support hold events, and system modifier keys are prohibited from assigning press events for security reasons. They also cannot be used for chords. Everything else is completely available.

### **> Dividing into layers**  
Organize assignment groups into different layers: basic assignments, extended characters, navigation, media control, etc.  
Each layer is managed separately, and current assignments are collected from all active layers.

Switching layers or groups of layers can be part of your assignments – add layer activation as an action for an event.  
`\+1 🡒 Toggle navigation layer activity`  
`\+2 🡒 Turn off all layers except n`  
`\+3 🡒 Enable layer set abc`

### **> Individual assignments for language layouts**  
In addition to global assignments, you can also link assignments to specific language layouts.  
[en] `o (hold) 🡒 “`, `. (hold) 🡒 ”`  
[de] `o (hold) 🡒 „`, `. (hold) 🡒 “`  
[ru] `o (hold) 🡒 «`, `. (hold) 🡒 »`  
[no] `a, e 🡒 æ`

You can set assignments for different layouts on each layer.

### **> GUI**

All of the above is assigned and configured via the GUI.

![](https://github.com/user-attachments/assets/e0ac4857-d159-4196-8a81-b09449b47680)

Go through any sequence of events, add assignments, link them to existing layers, or create new ones.  
All assignments, with additional indicators, the number of child transitions, and the display of cross-assignments from different layers—everything is right in front of your eyes. For example:

![](https://github.com/user-attachments/assets/a5a656bd-8e46-4272-9c36-cdff8209f15f)
> A modified layout is not a reassignment, it is simply a [different layout](https://github.com/uqqu/layout)

All added assignments become available for use immediately. Change functionality on the fly.

---

## 🎮 Usage

0. **Clone** this repo
    - *(optional)* Install AutoHotkey v2
1. **Run** `main.exe` or `main.ahk`
   - When you first launch the app, cycle through all your installed layouts and configure the display and behavior of the GUI via 🔧 in the lower right corner
2. **Try** some of predefined layers
3. **Define** your own assignments
4. **Use** new assignments immediately, without restarts
5. **Add** `main.*` to the system startup

### 🔧 Prerequisites

- Windows 10+
- *(optional)* AutoHotkey v2

---

## ⚡ Experimental C Core Engine

For lower latency and more functionality, there is a test reimplementation in C. So far only a working minimum without GUI, customizations, with limitations of system modifiers.

---

## 🖥️ Detailed description of the GUI

> Alternative description in article format [on Habr](https://habr.com/ru/articles/900000/) (in Russian)

### 🗺️ Visual Cues & Navigation

#### **Keyboard/mouse buttons**
The text on the button — assignments on tap (above) and hold (below), if any. Each assignment can have a name added to it, which will be displayed in the GUI instead of the value itself.

Colored frame — indicates a special type of hold: yellow indicates chord components; blue indicates user modifiers; black indicates currently active in the GUI modifiers that are taken into account for displaying current assignments.

Additional colored indicators display the fine-tuned settings for each assignment: at the top of the button for the base assignment; at the bottom for the hold assignment. In the right corner, a red counter or simply an indicator (changeable in settings) displays the number/availability of child transitions (also works for modifiers, including combined ones). On the left side are indicators of changed click settings. In order of display:  
- The silver indicator shows that the name for the GUI of the assignment has been changed (to avoid confusion)
- Gray – a non-returnable assignment has been set
- Teal – independent activation
- Blue – additional action on release
- Purple – modified hold activation time
- Pink – modified waiting time for the next press for child transitions (only for the next level)

In the upper right corner, there is a non-clickable information button that displays the current value of active GUI modifiers or their combinations.
Mouse buttons are located around the numpad. The display of additional rows of keys can be enabled in the settings, if necessary.

#### **Transitions**
Pressing and holding physical keys on the keyboard/mouse will take you to the corresponding level of the assignment chain. Alternatively, use the mouse – left click to move with a tap event, right click to hold event. After moving, new items will open for editing or clearing values along the current path.

#### **Path**
Above the layout template is a menu showing the path to the current level of the chain (the current destination node).

The arrows indicate the type of transition: ➤ for a tap, ▲ for a hold, and ▼ for a chord. If the arrow is accompanied by a number (such as `2➤`), it means that this transition was performed with the corresponding modifier value (this can be either a single modifier or a combination of modifiers – based on the sum of their values).  
To return to any of the previous levels, click on the corresponding label. The transition modifier value for that level will be saved. Clicking on the current level label (the last one in the path) will reset all active modifiers.

### ⌨ Layouts
You can create assignments for a single keyboard layout or global, for all of them at once.

Near the settings button, there is a drop-down list with your layouts (as well as global assignments – `Global`). Layouts found in your layers will also be added to this list, even if these layers are inactive (configurable).
> In the GUI, for greater control, you can see global assignments and assignments for each layout separately. But during the execution of the main script, these assignments are mixed — **global assignments are added to each layout**, with priority given to specific layouts in case of cross-assignments. For example, when assigning [Global] `o (hold) 🡒 "`, `. (hold) 🡒 "` and [en] `o (hold) 🡒 “`, `. (hold) 🡒 ”`, the assignment “” will work when the en layout is active, and "" on all others.

### 🌫️ Layers
The list on the left displays all layers found in `layers\` `*.json`. Set the layer activity by changing the checkbox. To interact with layers, use the buttons below the list – change its relative priority (this affects cross-assignments), edit the name, delete and add new ones.

Double-clicking on any layer will take you to a separate viewing and editing mode for that layer, without being tied to the currently active layers.

Also, the list of layers at the root level displays the total number of assignments on different layouts, and – at specific transition levels, – it displays assignments and the number of transitions from it from different layers *along the current path*. You always know what is happening on this node on all layers. By default, values from inactive layers are not collected or displayed for better performance, but you can temporarily change this behavior in the settings.

### 📌 Predefined layers
Several layers are placed directly in the repository so that you can familiarize yourself with the usage and capabilities before assigning your own or adapting existing ones to suit your needs:
- **Default**: 83 additional extended punctuation characters in the alphabetic part with only one modifier.<details><summary></summary>
  ![](https://github.com/user-attachments/assets/b764bb7c-b1ee-4490-9306-9f9a07638aa2)
  ![](https://github.com/user-attachments/assets/d957a3eb-41cb-4100-b6b4-bde7911fa9d7)</details>
- **Controlling Keys**: a new perspective on the familiar positioning of control keys. It also features additional media keys, hjkl navigation, and several everyday functions, such as increasing/decreasing the number under the cursor, CAPS on one word, delayed start/stop of music, and other small features.<details><summary></summary>
  ![](https://github.com/user-attachments/assets/0420b99f-03ad-43e0-a772-c200ff4d605d)
  ![](https://github.com/user-attachments/assets/13ff030d-20a1-4634-bc5d-0f8751ce6b78)</details>
- **Leader**: a dozen functions under a single button. As a template for your customization.<details><summary></summary>
  ![](https://github.com/user-attachments/assets/c48be9bd-3297-4bd7-a2dc-18baa88507a2)
  ![](https://github.com/user-attachments/assets/c005c286-41a2-4f42-bdb6-391e1c800a9c)</details>
- **Mouse**: 38 ~parrots~ assignments for quick access using all mouse events via side modifier buttons and their combinations. From navigation and media control to random password generation and link shortening functions.<details><summary></summary>
  ![](https://github.com/user-attachments/assets/74f43968-ecfa-4ced-b3c2-8fd56b7b948b)
  ![](https://github.com/user-attachments/assets/362e57fc-2c6a-41eb-bae3-418de6875e34)
  ![](https://github.com/user-attachments/assets/f374cbf5-0dfb-4f74-a5b6-be025f2b54ed)</details>
- **Emoji**: and how many of them are there?..<details><summary></summary>
  ![](https://github.com/user-attachments/assets/ce50189f-6fd5-432b-a56f-460906bb042b)</details>
- **Extra langs**: yoü use å separate łayout for a couple of ñew letters? There are 12 for each script, and a whole row of global diacritics. Write in any language ø. *(layout đependent)*<details><summary></summary>
  ![](https://github.com/user-attachments/assets/bd888770-de73-40ac-aeea-2b5bb59c0ad5)
  ![](https://github.com/user-attachments/assets/1adcef14-dbb8-40bf-a1be-a0ac55fea6f9)
  ![](https://github.com/user-attachments/assets/5e8fb2de-a09a-4188-9dbb-4e541022165a)</details>
- **Morse**: you’ve only seen it on TV? You can try it for yourself.<details><summary></summary>
  ![](https://github.com/user-attachments/assets/8f5be4a9-0595-4c68-b852-47c6b2e3e13a)
  ![](https://github.com/user-attachments/assets/92505abe-7c6d-4e6f-a932-511e5ee107b8)</details>
- **Angry**: one of the variants of using the `Instant` option. Don’t swear.<details><summary></summary>
  ![](https://github.com/user-attachments/assets/50c1a660-40d2-4b7e-8684-5aead1b2988f)</details>
- **NumLock** and **One word caps**: auxiliary layers toggled from other layers via the custom `ToggleLayers` function.
- **…and a lot more of your own?**

### 🎨 Defining first assignments
To add or change an assignment, press the corresponding key on your keyboard/mouse or click on it in the interface. After pressing, the `Base` and `Hold` panels will appear in the upper right corner. `Base` is responsible for the assignment on tap, and `Hold`, respectively, when held down. Clicking on them will open a form for changing/adding an assignment.

#### Types of actions
There are several types of actions that you can select for assignment in the corresponding list:
- **Plain text** – any string you would like to enter. Some unique symbol, your duty email, a cherry pie recipe, whatever you want.
- **Key simulation** – commands in AHK-syntax, like `{SC010}`, `+^{Left}`, `{End}{Shift down}{Home}{Shift up}{Backspace}`, to simulate certain keystrokes. You can read the syntax in detail on the [AHK website](https://www.autohotkey.com/docs/v2/KeyList.htm).
- **Modifier** – when creating an assignment for hold action, the modifier type is available. When assigning this type, specify its numerical value (usually just an ordinal number), which will be used for assignments from it. Combined modifiers are obtained from the sum of the values of **different** assigned modifiers.
- **Disabled** and **Default** – are basic types that may be needed when configuring auxiliary keys in a transition chain.
- **Function call** – any of the existing ones, or your own AHK function, such as `SendCurrentDate` or `ExchRates(USD, RUB)`.
  - String values are specified *without* quotation marks, and `,` and `[` in strings should be escaped with `\`; if the function does not accept parameters, you can omit the parentheses, leaving only the function name.
  - To simplify assignments, main user functions can be assigned via a submenu that appears when the corresponding menu item is selected.  
![](https://github.com/user-attachments/assets/24b91c96-e602-483c-805e-1e627c90c506)

#### Additional parameters
In addition to selecting the action type and the action value itself, you can also set additional parameters such as:
- Instant activation – makes the assignment independent of child transitions, performing the assigned action immediately when the event is triggered. The chain of transitions is not lost and you can continue diving.
- Irrevocable press – prevents returning to the root from the current press. Normally, the return occurs when the leaf (the last element of the assignment chain) is reached, or when the timer for waiting for the next press (if any) expires. With this option this does not happen, and you remain at the current level if there are no child assignments, or in an unlimited wait for the next press. By default, irrevocable option is offered for all assignments from under modifiers, to allow multiple value entry.
- Modified hold timeout – the value in ms that will be used to distinguish tap/hold, instead of the globally specified value. ⚠ This applies specifically to base assignments. In other words, you specify when the base event will turn into a hold event.
- Modified child press wait time – like the previous one, in ms, replaces global. Works only for one level under the given assignment.
- Additional release action – calls another action of the specified type and value when the key of the catched assignment is released. The action will be recorded at the moment of catching the whole assignment, and will not be broken by any transitions.
- GUI shortname – purely for visually enhancing your layers in the GUI. Useful for almost all assignments except single character texts.

If you’re in edit mode for a specific layer, or if you have only one active layer, the assignment will be automatically linked to it. Otherwise, an additional list is displayed to select the layer to which the assignment will be linked.

> System modifier keys can only be assigned a user modifier action, without other settings.

### ✨ How it works

When you press a key, the script checks if there is in the current transition table both base and hold assignments.
- If there is only the base, it goes into the next check. No unnecessary branching delays if they are not needed.
- If there is a hold assignment, the program checks if the key will be held for the specified number of ms.
- Releasing the checked key before the timer is considered as a basic tap.
- Holding for the specified time will send the hold assignment to the next check, without being tied to the subsequent release of the key.

#### Transition
After determining the assignment (tap or hold) it checks its own nested transition table. If it is not empty, the link to the current transition table/node is changed, and the script waits for the next event based on the global (or specified for this assignment) timer value, without performing the current assignment action. If the `Instant` option is added to the assignment, the action will be performed immediately, and the link to the table will also move to the next node, waiting for a new key.
- If there are no new events for the given timer, the last action will be executed (hereinafter – if not already executed by `Instant`) and the transition table returns to the root table, if the `Irrevocable` option is not specified.
- If there is no assignment for the next event in the current transition table, the previous, unsent assignment is executed, and the new event is processed from the root transition table.
- If the event from the next press is present in the transition table, it starts from the first point of this paragraph (from checking the base and hold assignments for the pressed key/button, …).

#### Return to root
Every time you reach the last event in the chain (leaf), or if the chain is interrupted by a timer, the table returns to the root state, except in cases of `Irrevocable`.

#### Timer delay
Special hold types such as `modifier` and `chord part` delay the timer, and while the corresponding keys are held down, table reset and action executing do not occur.

#### No-return event
By default no return occurs when entering via `modifier`. As long as the modifier is held down, you can perform any number of keystrokes for the current table, and the return will only occur when the modifier is released.
- But this does not prevent from moving to deeper levels of nesting. The transition, even with a modifier, returns us to the second point of the block (from checking the nested table).
- Also, with each transition, the value of the mismatched modifiers is reset, and the timer delay no longer works.

#### Return transition
Every time you reach the last assignment in the chain, you return to the initial table. But not in the case of modifiers – pressing them by default keeps you at the current node, allowing you to access any number of assignments along that path. Even pressing non-assigned keys at this node will not reset you. The return will occur when you release all modifiers. But you can still go deeper if the local assignment have a non-empty transition table, in which case the previously active modifier will no longer serve as protection against reset.

#### Modifiers in the GUI
Assigned modifiers are displayed with a blue border, while currently active (held down) modifiers change their border to black. The total value of active modifiers is displayed on the auxiliary button in the upper right corner of the keyboard layout.  
The values of the modifiers themselves are displayed at the bottom of the button, as are other hold values (if no custom name is specified).  
To toggle modifier activity in the GUI, right-click on it or hold down the corresponding physical key (except Alt and LBM-RBM).  

> Pressing modifiers does not affect the transition; they only change a single value within a current node, which will be taken into account for other assignments.

### 🎶 Chords
The right list shows chords valid at your current path. Click `New` to enter chord‑selection mode, press or click your desired combination, then assign it just like usual tap/hold value.

> If two chords share a common key combo, both will fire when pressed.

#### Chord nesting
Chords themselves can nest further. You can add assignment under chord, chord under chord, whatever you like. Double-click on a chord line to jump to the nested table.

#### ModChords
Chords work with modifiers, and although mechanically it is one large chord, modifiers are not considered to be keys within it. When you add or edit a chord, the currently assigned modifiers are not selectable. Also, mouse buttons and additional multimedia-office row keys are not available for chords.

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
- **GUI** – lots of valuable little things to fix.
- …and of course you can just spread the word and share the link with your friends, acquaintances, and, maybe, subscribers 👾

> 🚧 The project is under active development and may contain bugs.
> Please report all problems and suggestions in the Issues section.