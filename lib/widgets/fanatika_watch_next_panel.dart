// Fanatika Continue Watching artwork row: no panel background or heading.
// A TV remote can navigate every show, including off-screen cards.
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
      // At the right edge, stay on the final show. No visible Refresh control.
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
        height: widget.expandVertical ? double.infinity : 242,
        child: shows.isEmpty
          ? const SizedBox.shrink()
          : SingleChildScrollView(
              controller: _posterScroll,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(children: [
                for (var index = 0; index < shows.length; index++) ...[
                  if (index > 0) const SizedBox(width: 14),
                  Builder(builder: (cardContext) => Focus(
                    canRequestFocus: false,
                    onKeyEvent: (_, event) => _cardKey(event, shows, index),
                    child: _WatchNextCompactCard(
                      key: ValueKey('${shows[index].id}_${shows[index].packageName}'),
                      item: shows[index], service: service,
                      focusNode: index == 0 ? widget.firstItemFocusNode : _nodeFor(shows[index]),
                      onItemFocused: () {
                        widget.onItemFocused?.call();
                        // Scroll the entire focused poster into view on a TV remote.
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

class _WatchNextCompactCardState extends State<_WatchNextCompactCard> {
  bool _focused = false;
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

  @override Widget build(BuildContext context) {
    final poster = widget.service.getCachedPoster(widget.item.posterUri);
    return SizedBox(width: 280, height: 206, child: Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13),
        side: BorderSide(color: _focused ? const Color(0xFFBEE9FF) : Colors.transparent,
          width: _focused ? 2.5 : 1)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        focusNode: widget.focusNode,
        onFocusChange: (focused) {
          if (mounted) setState(() => _focused = focused);
          if (focused) widget.onItemFocused?.call();
        },
        onTap: () => widget.service.launchItem(widget.item),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Preserve the WHOLE Plex artwork (including portrait posters).
          // BoxFit.cover cropped titles and faces in the previous version.
          Expanded(child: Center(
            child: poster != null
              ? Image.memory(poster, fit: BoxFit.contain,
                  width: double.infinity, height: double.infinity,
                  gaplessPlayback: true,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.movie_outlined, size: 35)))
              : const Center(child: Icon(Icons.movie_outlined,
                  size: 35, color: Colors.white70)),
          )),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            // Show only the title: never prepend the Plex source name.
            child: Text(widget.item.title, maxLines: 1, overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white,
                shadows: [Shadow(color: Colors.black, blurRadius: 7)],
                fontWeight: FontWeight.w600, fontSize: 13))),
        ]),
      ),
    ));
  }
}
