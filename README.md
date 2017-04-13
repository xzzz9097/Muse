## <img src=Muse/Assets.xcassets/AppIcon.appiconset/icon-512@2x.png width="32"> Muse

An open-source Spotify, iTunes and Vox controller with TouchBar support, system-wide TouchBar controls (à la iTunes) and Spotify account integration.

- [Demo video (old release)](https://www.youtube.com/watch?v=1hxwfGBvghg)
- [Spotify integration](https://www.youtube.com/watch?v=zW4QomjDNN8)

<img src=Screenshots/Window.png width="387"><img src=Screenshots/Window2.png width="387">
<img src=Screenshots/TouchBar.png width="1094">
<img src=Screenshots/TouchBar2.png width="1094">

### Download
[2.0](https://github.com/xzzz9097/Muse/releases/tag/v2.0-beta.1)

### Usage
Summon it with <kbd>control</kbd> + <kbd>command</kbd> + <kbd>s</kbd>
You'll be greeted with an album art window in the middle of the screen, and the playback controls on your TouchBar. Pressing the hotkey one more time makes them both disappear, and they also auto-hide when you focus another application. Bring up the window and press <kbd>command</kbd> + <kbd>q</kbd> or <kbd>esc</kbd> to quit the app.
System-wide now playing controls are also accessible from the leftmost button of the control strip, just like iTunes and Safari ones.
Spotify, iTunes and Vox are currently supported. The app automatically guesses the right player to control basing on availability and playback notifications, but you can manually toggle them with the shortcuts described below.

### Keyboard shortcuts
Several handy shortcuts are provided when the popup window is open:

|                Keystroke                |        Action         |
|:---------------------------------------:|:---------------------:|
|    <kbd>s</kbd> and <kbd>space</kbd>    |   toggle play/pause   |
| <kbd>a</kbd> and <kbd>left arrow</kbd>  |    previous track     |
| <kbd>d</kbd> and <kbd>right arrow</kbd> |      next track       |
|              <kbd>w</kbd>               | focuses player window |
|              <kbd>r</kbd>               |   toggles repeating   |
|              <kbd>x</kbd>               |   toggles shuffling   |
|              <kbd>l</kbd>               |      likes track      |
|              <kbd>1</kbd>               |   controls Spotify    |
|              <kbd>2</kbd>               |    controls iTunes    |
|              <kbd>3</kbd>               |     controls Vox      |

### Libraries
- [Swiftify](https://github.com/xzzz9097/Swiftify) by @xzzz9097
- [NSImageColors](https://github.com/xzzz9097/NSImageColors) by @jathu
- [DDHotKey](https://github.com/davedelong/DDHotKey) by @davedelong
