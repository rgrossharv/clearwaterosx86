loadTemplate("org.kde.plasma.desktop.defaultPanel")

var image = "file:///usr/share/wallpapers/ClearwaterOS/contents/images/clearwater.jpg"
var desktopsArray = desktopsForActivity(currentActivity());
for (var j = 0; j < desktopsArray.length; j++) {
    desktopsArray[j].wallpaperPlugin = "org.kde.image";
    desktopsArray[j].currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    desktopsArray[j].writeConfig("Image", image);
}
