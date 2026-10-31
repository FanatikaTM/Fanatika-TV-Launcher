// Fanatika Continue Watching artwork row with Google TV-style rounded cards.
// No background heading, no refresh button, and the full artwork stays visible.
import 'dart:math' as math;

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
              // Confine posters to their column: the adjacent weather card must
              // never receive paint from off-screen Watch Next items.
              clipBehavior: Clip.hardEdge,
              // Inner breathing-room lets the white ring stay visible without
              // allowing poster content to escape over the weather panel.
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
  @override void initState() {
    super.initState();
    widget.service.ensurePosterLoaded(widget.item.posterUri);
  }

  @override void didUpdateWidget(covariant _WatchNextCompactCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.posterUri != widget.item.posterUri) {
      widget.service.ensurePosterLoaded(widget.item.posterUri);
    }
  }

  @override void dispose() {
    _pulse.dispose();
    super.dispose();
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
    final artworkAccent = widget.service.getPosterAccent(widget.item.posterUri);
    return SizedBox(
      width: 272,
      height: 226,
      child: AnimatedBuilder(
        animation: _pulseCurve,
        builder: (context, child) {
          final t = _focused ? _pulseCurve.value : 0.0;
          // White halo on selection; artwork color is almost imperceptible.
          // The accent is already cached by WatchNextService before a poster
          // is displayed, so it never jumps to a new color after focusing.
          final glow = artworkAccent.withValues(alpha: 0.055 + (t * 0.035));
          return AnimatedScale(
            duration: const Duration(milliseconds: 170),
            // Avoid scaling a poster over the neighboring weather panel.
            scale: 1.0,
            curve: Curves.easeOutCubic,
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: _focused ? [
                      BoxShadow(color: Colors.white.withValues(alpha: 0.10 + (t * 0.15)),
                        blurRadius: 11 + (t * 9), spreadRadius: 0.5),
                      BoxShadow(color: glow, blurRadius: 16 + (t * 4), spreadRadius: 0.5),
                    ] : const [],
                  ),
                  child: child,
                ),
                // Paint the breathing WHITE stroke ON TOP of the filled card.
                // Previously the border was underneath an opaque Material,
                // making the animation effectively invisible on the TV.
                if (_focused) IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.42 + (t * 0.58)),
                        width: 1.8 + (t * 2.0),
                      ),
                    ),
                  ),
                ),
              ],
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
              } else {
                _pulse.stop();
                _pulse.value = 0;
              }
            },
            onTap: () => widget.service.launchItem(widget.item),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              decoration: BoxDecoration(
                // Restore the original translucent NAVY/BLUE palette instead
                // of the saturated cyan that obscured the mountain wallpaper.
                // The card fill is steady; only its WHITE selection ring pulses.
                color: _focused ? const Color(0xB52A619B) : const Color(0xA819477D),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: _focused ? Colors.white.withValues(alpha: 0.16)
                    : Colors.white.withValues(alpha: 0.20),
                  width: 1.0,
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
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFB6DDF4)),
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
