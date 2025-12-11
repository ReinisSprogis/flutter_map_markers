import 'dart:ui' as ui;
///Canvas that don't do anything.
///This is used to get bounds from canvas function from TileMarker class
///without actually drawing anything.
class NoOpCanvas implements ui.Canvas {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}