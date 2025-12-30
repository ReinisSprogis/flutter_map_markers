/// Defines the different animation modes for sprite markers.
/// 
/// Used to control how animated sprites behave.
/// 
/// loop: The animation loops continuously from start to end.
/// 
/// once: The animation plays once from start to end and then stops.
/// 
/// pingPong: The animation plays from start to end and then reverses back to start, repeating this cycle.
/// 
/// reverse: The animation plays continuously from end to start.
/// 
/// random: The animation displays frames in a random order.
enum AnimationMode {
  loop,
  once,
  pingPong,
  reverse,
  random,
}