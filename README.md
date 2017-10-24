## <img src=Muse/Resources/Assets.xcassets/AppIcon.appiconset/icon-512@2x.png width="32"> Muse

An open-source Spotify, iTunes and Vox controller with TouchBar support, system-wide TouchBar controls (à la iTunes) and Spotify account integration.

- [Control strip integration](https://www.youtube.com/watch?v=CdnKpR36cGU)
- [Demo video (old release)](https://www.youtube.com/watch?v=1hxwfGBvghg)
- [Spotify integration](https://www.youtube.com/watch?v=zW4QomjDNN8)

<img src=Screenshots/Window.png width="387"><img src=Screenshots/Window2.png width="387">
<img src=Screenshots/TouchBar.png width="1094">
<img src=Screenshots/TouchBar2.png width="1094">

### Download
New: [4.0 alpha](https://github.com/xzzz9097/Muse/releases/tag/v4.0-alpha.1)
[3.0](https://github.com/xzzz9097/Muse/releases/tag/v3.0-beta.1)

### Control strip integration
Muse appends a permanent button to the control strip (right tray bar) of the TouchBar, displaying album art and playback time. You can tap it to reveal the full control bar, long press it to toggle play/pause and swipe on it to jump to next or previous track.

### Installation
The app is not code signed, so after trying to open it unsuccessfully (because of GateKeeper) head to System Preferences -> Security & Privacy and manually grant it permission.
At first start you'll be prompted to log into your Spotify account. It's not strictly necessary but it allows adding/removing favourites to your library.

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
|              <kbd>i</kbd>               |      shows title      |
|              <kbd>1</kbd>               |   controls Spotify    |
|              <kbd>2</kbd>               |    controls iTunes    |
|              <kbd>3</kbd>               |     controls Vox      |

### Build
The project is not code-signed, just clone the repository, install the pods and open the workspace file.
```
git clone https://github.com/xzzz9097/Muse && cd Muse/ && pod install && open Muse.xcworkspace
```

### Libraries
- [SpotifyKit](https://github.com/xzzz9097/SpotifyKit) by @xzzz9097
- [NSImageColors](https://github.com/xzzz9097/NSImageColors) by @jathu
- [DDHotKey](https://github.com/davedelong/DDHotKey) by @davedelong
