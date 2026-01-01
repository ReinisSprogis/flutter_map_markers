/// Defines the different animation modes for sprite markers.
///
/// Used to control how animated sprites behave.
///
/// loopForward: The animation loops continuously loops forward through the frames.
///
/// forwardOnce: The animation plays once to last frame and then stops.
/// If animation starts at the frame that is considered last, animation will stop immediately.
///
/// reverseOnce: The animation plays once to start and then stops.
/// If animation starts at the frame that is considered first, animation will stop immediately.
/// 
/// pingPong: The animation plays from start to end and then reverses back to start, repeating this cycle continuously.
///
/// random: The animation displays frames in a random order continuously.
enum AnimationMode {
  loopForward,
  loopBackward,
  forwardOnce,
  reverseOnce,
  pingPong,
  random,
}
