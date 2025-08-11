import 'package:flutter/material.dart';

final List<Gradient> gradients = [
  const LinearGradient(
    colors: [Colors.blue, Colors.purple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ),
  LinearGradient(
    colors: [Colors.blue.withValues(alpha: .5), Colors.purple.withValues(alpha: .5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ),
  const LinearGradient(
    colors: [Colors.orange, Colors.red],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  ),
  LinearGradient(
    colors: [Colors.orange.withValues(alpha: .5), Colors.red.withValues(alpha: .5)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  ),
  const LinearGradient(
    colors: [Colors.green, Colors.yellow],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  ),
  LinearGradient(
    colors: [Colors.green.withValues(alpha: .5), Colors.yellow.withValues(alpha: .5)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  ),
  const LinearGradient(
    colors: [Colors.teal, Colors.cyan],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  ),
  LinearGradient(
    colors: [Colors.teal.withValues(alpha: .5), Colors.cyan.withValues(alpha: .5)],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  ),
  const LinearGradient(
    colors: [Colors.pink, Colors.deepPurpleAccent],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  ),
  LinearGradient(
    colors: [Colors.pink.withValues(alpha: .5), Colors.deepPurpleAccent.withValues(alpha: .5)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  ),
  const LinearGradient(
    colors: [Colors.indigo, Colors.lightBlueAccent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ),
  LinearGradient(
    colors: [Colors.indigo.withValues(alpha: .5), Colors.lightBlueAccent.withValues(alpha: .5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ),
  const LinearGradient(
    colors: [Colors.amber, Colors.deepOrange],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  ),
  LinearGradient(
    colors: [Colors.amber.withValues(alpha: .5), Colors.deepOrange.withValues(alpha: .5)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  ),
  const LinearGradient(
    colors: [Colors.lime, Colors.greenAccent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ),
  LinearGradient(
    colors: [Colors.lime.withValues(alpha: .5), Colors.greenAccent.withValues(alpha: .5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ),
];