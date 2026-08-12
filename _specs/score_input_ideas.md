# score input

## Overview

I want to think about entering score UI.  I want to explore Ideas for facilitaing score entry.   The primary mode is mobile touch screen, so that is paradigm we are working with.   

### single final score vs running score.
earlier we identified the concept of a single final score and concept of a running score.   I think both of these are the same thing in our paradigm, since we have the philosophy that the user dictates game over, and the app doesn't dictate game over, this kind of makes the idea of a running score and single score the same, in my opinion.  

I think the distinction is really a UI concern, in that in one case user is entering a single value per player, the other case they are adjusting a value per player.   My take is we have a score entry experience that facilitates both, entering a score or adjusting a score.  even in the case of a single final score, it can be looked at as adding the final score to 0 (an adjustment).

## Quick Adjust controls (increment/decrement)
On idea is to present the current score and have a decrement '-' just to left of the number and '+' just to right of number.  so that in the main score view, one can tap on the rights side of the score to increment and on the left side to decrement (by 1).  Perhaps this is a template setting of "EnableQuickAdjust" or something.   

## on screen keyboard
I could see tapping the score, in the middle, bringing up a custom 'keyboard', where one can type a number (think calculate/numpad layout), and then have two options for "submitting" that:
- Replace = this would replace the current value with whatever was entered.
- Add To Existing = this would adjust the current score, adding the entered value.  

The UI could make it clear what the new value would be for each option.  
The input would also need to account for indicating negative value.  

## score display UI.  
The score display UI in this case would not be a traditional input box, but rather a label that reacted to being clicked.  It would not use the standard device keyboard.  The score could be presented in a larger font making the click area bigger.

The idea is that the score value template would define behavior of the UI.  Does it have the Quick Adjust enabled, does it have the "TapToEdit" enabled. 

some score values may be calculated only have no direct entry, they are derived by other score value elements, hence the ability of to enable and disable these options on a score value basis in the template.