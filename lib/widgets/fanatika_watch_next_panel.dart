// Fanatika Continue Watching artwork row with Google TV-style rounded cards.
// No background heading, no refresh button, and the full artwork stays visible.
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flauncher/models/watch_next_item.dart';
import 'package:flauncher/providers/watch_next_service.dart';

class FanatikaWatchNextPanel extends StatefulWidget {
  final VoidCallback? onItemFocused;
  final VoidCallback? onNavigateUp;
  final VoidCallback? onNavigateDown;
  final bool expandVertical;
  final FocusNode? firstItemFocusNode;
  const FanatikaWatchNextPanel({super.key, this.onItemFocused,
    this.onNavigateUp, this.onNavigateDown,
    this.expandVertical = false, this.firstItemFocusNode});

  @override State<FanatikaWatchNextPanel> createState() => _FanatikaWatchNextPanelState();
}

class _FanatikaWatchNextPanelState extends State<FanatikaWatchNextPanel> {
  final ScrollController _posterScroll = ScrollController();
  final Map<String, FocusNode> _cardNodes = {};
  FocusNode _nodeFor(WatchNextItem item) => _cardNodes.putIfAbsent(
    '${item.id}_${item.packageName}', () => FocusNode(debugLabel: 'Continue Watching ${item.id}'));

  @override void dispose() {
    _posterScroll.dispose();
    for (final node in _cardNodes.values) { node.dispose(); }
    super.dispose();
  }

  void _focusCard(List<WatchNextItem> items, int index) {
    if (index < 0 || index >= items.length) return;
    final node = index == 0 && widget.firstItemFocusNode != null
      ? widget.firstItemFocusNode! : _nodeFor(items[index]);
    node.requestFocus();
  }

  KeyEventResult _cardKey(KeyEvent event, List<WatchNextItem> items, int index) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowRight) {
      if (index + 1 < items.length) _focusCard(items, index + 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      if (index > 0) _focusCard(items, index - 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      widget.onNavigateUp?.call();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      widget.onNavigateDown?.call();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override Widget build(BuildContext context) => Consumer<WatchNextService>(
    builder: (context, service, _) {
      final shows = service.canShowItems ? service.items : <WatchNextItem>[];
      return SizedBox(
        height: widget.expandVertical ? double.infinity : 252,
        child: shows.isEmpty
          ? const SizedBox.shrink()
          : SingleChildScrollView(
              controller: _posterScroll,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(children: [
                for (var index = 0; index < shows.length; index++) ...[
                  if (index > 0) const SizedBox(width: 16),
                  Builder(builder: (cardContext) => Focus(
                    canRequestFocus: false,
                    onKeyEvent: (_, event) => _cardKey(event, shows, index),
                    child: _WatchNextCompactCard(
                      key: ValueKey('${shows[index].id}_${shows[index].packageName}'),
                      item: shows[index], service: service,
                      focusNode: index == 0 ? widget.firstItemFocusNode : _nodeFor(shows[index]),
                      onItemFocused: () {
                        widget.onItemFocused?.call();
                        Scrollable.ensureVisible(cardContext,
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic, alignment: 0.06);
                      },
                    ),
                  )),
                ],
              ]),
            ),
      );
    },
  );
}

class _WatchNextCompactCard extends StatefulWidget {
  final WatchNextItem item;
  final WatchNextService service;
  final VoidCallback? onItemFocused;
  final FocusNode? focusNode;
  const _WatchNextCompactCard({super.key, required this.item, required this.service,
    this.onItemFocused, this.focusNode});

  @override State<_WatchNextCompactCard> createState() => _WatchNextCompactCardState();
}

class _WatchNextCompactCardState extends State<_WatchNextCompactCard>
    with SingleTickerProviderStateMixin {
  bool _focused = false;
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1150),
  );
  late final Animation<double> _pulseCurve = CurvedAnimation(
    parent: _pulse,
    curve: Curves.easeInOut,
  );
  Color _glowColor = const Color(0xFF88D9FF);
  String? _loadedPosterUri;

  @override void initState() {
    super.initState();
    _loadPosterAndAccent();
  }

  @override void didUpdateWidget(covariant _WatchNextCompactCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.posterUri != widget.item.posterUri) {
      _loadPosterAndAccent();
    }
  }

  @override void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _loadPosterAndAccent() async {
    widget.service.ensurePosterLoaded(widget.item.posterUri);
    final posterUri = widget.item.posterUri;
    if (posterUri == null || posterUri.isEmpty) return;
    final bytes = widget.service.getCachedPoster(posterUri);
    if (bytes == null || bytes.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final later = widget.service.getCachedPoster(posterUri);
        if (later != null && later.isNotEmpty) {
          await _updateAccentFromBytes(later, posterUri);
        }
      });
      return;
    }
    await _updateAccentFromBytes(bytes, posterUri);
  }

  Future<void> _updateAccentFromBytes(Uint8List bytes, String posterUri) async {
    final color = await _extractDominantColor(bytes);
    if (!mounted) return;
    setState(() {
      _loadedPosterUri = posterUri;
      _glowColor = color;
    });
  }

  Future<Color> _extractDominantColor(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 36, targetHeight: 36);
      final frame = await codec.getNextFrame();
      final data = await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (data == null) return const Color(0xFF88D9FF);
      final rgba = data.buffer.asUint8List();
      int r = 0, g = 0, b = 0, samples = 0;
      for (int i = 0; i + 3 < rgba.length; i += 16) {
        final a = rgba[i + 3];
        if (a < 140) continue;
        final rr = rgba[i];
        final gg = rgba[i + 1];
        final bb = rgba[i + 2];
        final brightness = (rr + gg + bb) / 3;
        if (brightness < 26) continue;
        r += rr;
        g += gg;
        b += bb;
        samples++;
      }
      if (samples == 0) return const Color(0xFF88D9FF);
      final avg = Color.fromARGB(255, (r / samples).round(), (g / samples).round(), (b / samples).round());
      final hsl = HSLColor.fromColor(avg);
      return hsl.withSaturation(hsl.saturation.clamp(0.35, 0.85))
        .withLightness(hsl.lightness.clamp(0.44, 0.66)).toColor();
    } catch (_) {
      return const Color(0xFF88D9FF);
    }
  }

  String _metaText() {
    final parts = <String>[];
    final duration = widget.item.duration;
    if (duration != null && duration > 0) {
      parts.add(_formatDuration(duration));
    }
    final progress = widget.item.progressPercent;
    if (progress != null && progress > 0) {
      parts.add('$progress% watched');
    }
    return parts.join(' • ');
  }

  String _formatDuration(int millis) {
    final d = Duration(milliseconds: millis);
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours > 0 && minutes > 0) return '$hours hr $minutes min';
    if (hours > 0) return '$hours hr';
    return '${math.max(1, minutes)} min';
  }

  @override Widget build(BuildContext context) {
    final poster = widget.service.getCachedPoster(widget.item.posterUri);
    final meta = _metaText();
    return SizedBox(
      width: 272,
      height: 226,
      child: AnimatedBuilder(
        animation: _pulseCurve,
        builder: (context, child) {
          final t = _focused ? _pulseCurve.value : 0.0;
          final glow = Color.lerp(_glowColor.withValues(alpha: 0.22), _glowColor.withValues(alpha: 0.42), t)!;
          return AnimatedScale(
            duration: const Duration(milliseconds: 170),
            scale: _focused ? 1.03 : 1.0,
            curve: Curves.easeOutCubic,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: _focused ? [
                  BoxShadow(color: glow, blurRadius: 26 + (t * 9), spreadRadius: 1.2 + (t * 1.2)),
                ] : const [],
              ),
              child: child,
            ),
          );
        },
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            focusNode: widget.focusNode,
            borderRadius: BorderRadius.circular(28),
            focusColor: Colors.transparent,
            onFocusChange: (focused) {
              if (mounted) setState(() => _focused = focused);
              if (focused) {
                widget.onItemFocused?.call();
                _pulse.repeat(reverse: true);
                if (_loadedPosterUri != widget.item.posterUri) {
                  _loadPosterAndAccent();
                }
              } else {
                _pulse.stop();
                _pulse.value = 0;
              }
            },
            onTap: () => widget.service.launchItem(widget.item),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: _focused ? 0.12 : 0.07),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: _focused ? const Color(0xFFE4F8FF) : Colors.white.withValues(alpha: 0.18),
                  width: _focused ? 2.8 : 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: AspectRatio(
                          aspectRatio: 2 / 3,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: poster != null
                              ? Image.memory(
                                  poster,
                                  fit: BoxFit.contain,
                                  gaplessPlayback: true,
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(Icons.movie_outlined, size: 34, color: Colors.white70),
                                  ),
                                )
                              : const Center(
                                  child: SizedBox(
                                    height: 26,
                                    width: 26,
                                    child: CircularProgressIndicator(strokeWidth: 2.4),
                                  ),
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                    ),
                  ),
                  if (meta.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                    ),
                  ],
                  if ((widget.item.progressPercent ?? 0) > 0) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 4,
                        value: (widget.item.progressPercent!.clamp(0, 100)) / 100.0,
                        backgroundColor: Colors.white.withValues(alpha: 0.10),
                        valueColor: AlwaysStoppedAnimation<Color>(_glowColor),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
