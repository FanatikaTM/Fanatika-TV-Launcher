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
  final FocusNode? refreshFocusNode;
  const FanatikaWatchNextPanel({super.key, this.onItemFocused,
    this.onNavigateUp, this.onNavigateDown,
    this.expandVertical = false, this.firstItemFocusNode, this.refreshFocusNode});

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
      else widget.refreshFocusNode?.requestFocus();
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
        child: Row(children: [
          Expanded(child: SingleChildScrollView(
            controller: _posterScroll,
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (var index = 0; index < shows.length; index++) ...[
                if (index > 0) const SizedBox(width: 12),
                Builder(builder: (cardContext) => Focus(
                  canRequestFocus: false,
                  onKeyEvent: (_, event) => _cardKey(event, shows, index),
                  child: _WatchNextCompactCard(
                    key: ValueKey('${shows[index].id}_${shows[index].packageName}'),
                    item: shows[index], service: service,
                    focusNode: index == 0 ? widget.firstItemFocusNode : _nodeFor(shows[index]),
                    onItemFocused: () {
                      widget.onItemFocused?.call();
                      // Keep each card fully visible when moving with the D-pad.
                      Scrollable.ensureVisible(cardContext,
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic, alignment: 0.08);
                    },
                  ),
                )),
              ],
            ]),
          )),
          const SizedBox(width: 12),
          Focus(canRequestFocus: false,
            onKeyEvent: (_, event) {
              if (event is! KeyDownEvent) return KeyEventResult.ignored;
              if (event.logicalKey == LogicalKeyboardKey.arrowLeft && shows.isNotEmpty) {
                _focusCard(shows, shows.length - 1); return KeyEventResult.handled;
              }
              if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                widget.onNavigateUp?.call(); return KeyEventResult.handled;
              }
              if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                widget.onNavigateDown?.call(); return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: Align(alignment: Alignment.topCenter,
              child: SizedBox(width: 60, height: 60,
                child: IconButton.filledTonal(
                  tooltip: 'Refresh shows',
                  focusNode: widget.refreshFocusNode,
                  iconSize: 30,
                  icon: const Icon(Icons.refresh),
                  onPressed: service.refreshPermissionAndItems,
                ),
              )),
          ),
        ]),
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
    return SizedBox(width: 222, height: 218, child: Material(
      color: _focused ? const Color(0xFF425A79) : const Color(0xDD1B3049),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13),
        side: BorderSide(color: _focused ? const Color(0xFFBEE9FF) : Colors.white24,
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
          Expanded(child: poster != null
            ? Image.memory(poster, fit: BoxFit.cover, gaplessPlayback: true,
                errorBuilder: (_, __, ___) => const Icon(Icons.movie_outlined, size: 35))
            : const Icon(Icons.movie_outlined, size: 35, color: Colors.white70)),
          Padding(padding: const EdgeInsets.all(8),
            // Show only the title: never prepend the Plex source name.
            child: Text(widget.item.title, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white,
                fontWeight: FontWeight.w600, fontSize: 13))),
        ]),
      ),
    ));
  }
}
