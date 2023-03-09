import 'package:animated_marker/animated_marker.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'
    show Marker, GoogleMap;

class AnimatedMarker extends StatefulWidget {
  /// Wrap a [GoogleMap] with this [AnimatedMarker] widget
  ///
  /// pass the [Set] of [Marker] to [markerPositions]
  ///
  /// then take the [animatedMarkers] from it's builder method and supply it
  /// to the [GoogleMap]'s [markers]
  ///
  /// this widget will then calculate and animate the [Marker] from
  /// it's old position to the new position automatically in the [duration]
  /// with a [curve]
  const AnimatedMarker({
    super.key,

    /// [Set] of [Marker] same as in [GoogleMap]
    required this.markerPositions,

    /// build your [GoogleMap] in this builder with the [animatedMarkers]
    required this.builder,

    /// default [duration] of 1 seconds
    this.duration = const Duration(seconds: 1),

    /// default [curve] of [Curves.ease]
    this.curve = Curves.ease,
  });
  final Set<Marker> markerPositions;
  final Widget Function(BuildContext context, Set<Marker> animatedMarkers)
      builder;
  final Duration duration;
  final Curve curve;

  @override
  State<AnimatedMarker> createState() => AnimatedMarkerState();
}

class AnimatedMarkerState extends State<AnimatedMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Set<Animation<Marker>> _markerAnimations;
  late Set<Marker> _lastMarkerPositions;
  late Set<Map<Marker, Marker>> _markerPairs;
  late Set<Marker> _currentMarkerPositions;

  @override
  void initState() {
    super.initState();

    /// initialize the last marker positions as the input marker positions
    _lastMarkerPositions = widget.markerPositions;

    /// initialize the current marker positions as the input marker positions
    _currentMarkerPositions = widget.markerPositions;

    /// create an animation controller with [duration]
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    /// create a list of marker pairs of the same [MarkerId] according to the
    /// input [markerPositions]
    _markerPairs = widget.markerPositions.map<Map<Marker, Marker>>((marker) {
      return <Marker, Marker>{
        marker: _lastMarkerPositions.firstWhere(
          (lastMarker) => lastMarker.markerId == marker.markerId,
          orElse: () => marker,
        )
      };
    }).toSet();

    /// create [MarkerTween] animations from the pair of markers
    _markerAnimations = _markerPairs.map<Animation<Marker>>(
      (pair) {
        return MarkerTween(
          begin: pair.values.first,
          end: pair.keys.first,
        ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
      },
    ).toSet();

    /// add a listener to the animation controller which returns
    /// [_currentMarkerPositions] from the builder
    _controller.addListener(() {
      setState(() {
        _currentMarkerPositions = _markerAnimations
            .map(
              (animation) => animation.value,
            )
            .toSet();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AnimatedMarker oldWidget) {
    super.didUpdateWidget(oldWidget);

    /// when the widget updates check if the old marker position is same as the
    /// new one, if not, update it with the latest
    /// and restart the animation controller
    if (oldWidget.markerPositions != widget.markerPositions) {
      _lastMarkerPositions = oldWidget.markerPositions;
      _controller.reset();
      _controller.forward();
    }

    /// update the list of marker pairs of the same [MarkerId] according to the
    /// input [markerPositions]
    _markerPairs = widget.markerPositions.map<Map<Marker, Marker>>((marker) {
      return <Marker, Marker>{
        marker: _lastMarkerPositions.firstWhere(
          (lastMarker) => lastMarker.markerId == marker.markerId,
          orElse: () => marker,
        )
      };
    }).toSet();

    /// update the [MarkerTween] animations from the pair of updated markers
    _markerAnimations = _markerPairs.map<Animation<Marker>>(
      (pair) {
        return MarkerTween(
          begin: pair.values.first,
          end: pair.keys.first,
        ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
      },
    ).toSet();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _currentMarkerPositions);
  }
}
