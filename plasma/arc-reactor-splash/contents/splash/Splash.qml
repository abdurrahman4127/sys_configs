import QtQuick

Item {
    id: root

    // Provided by ksplashqml (0..6). Unused: the reactor loop is the whole show.
    property int stage

    AnimatedImage {
        anchors.fill: parent
        source: "images/arc-reactor.gif"
        fillMode: Image.PreserveAspectCrop
        playing: true
        loops: AnimatedImage.Infinite
        asynchronous: true
        cache: false
        smooth: true
    }
}
