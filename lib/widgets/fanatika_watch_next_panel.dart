// Fanatika compact Watch Next: placed beside Weather, above the selected app title.
// Content comes from Android's TV Provider. It is never fabricated by the launcher.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flauncher/models/watch_next_item.dart';
import 'package:flauncher/providers/watch_next_service.dart';

class FanatikaWatchNextPanel extends StatelessWidget {
  final VoidCallback? onItemFocused;
  final VoidCallback? onNavigateUp;
  final bool expandVertical;
  final FocusNode? firstItemFocusNode;
  const FanatikaWatchNextPanel({super.key, this.onItemFocused,
    this.onNavigateUp, this.expandVertical = false, this.firstItemFocusNode});

  @override
  Widget build(BuildContext context) {
    return Consumer<WatchNextService>(builder: (context, service, _) {
      return Focus(
        canRequestFocus: false,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.arrowUp
              && onNavigateUp != null) {
            onNavigateUp!();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Container(
        height: expandVertical ? double.infinity : 242,
        padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
        decoration: BoxDecoration(
          color: const Color(0xA5101F38),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.ondemand_video_outlined, color: Colors.white, size: 19),
            const SizedBox(width: 8),
            const Expanded(child: Text('Watch Next',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700,
                color: Colors.white))),
            IconButton(
              tooltip: 'Refresh Watch Next',
              icon: const Icon(Icons.refresh, size: 20, color: Colors.white70),
              onPressed: service.refreshPermissionAndItems,
            ),
          ]),
          const SizedBox(height: 4),
          Expanded(child: _body(context, service)),
        ]),
      ));
    });
  }

  Widget _body(BuildContext context, WatchNextService service) {
    // Keep the home uncluttered. Access requests and Plex errors remain in
    // Watch Next settings; never show placeholder warnings over the wallpaper.
    if (!service.canShowItems || service.isLoading || !service.hasItems) {
      return const SizedBox.shrink();
    }
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: service.items.length,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (context, index) => _WatchNextCompactCard(
        key: ValueKey('${service.items[index].id}_${service.items[index].packageName}'),
        item: service.items[index],
        service: service,
        focusNode: index == 0 ? firstItemFocusNode : null,
        onItemFocused: onItemFocused,
      ),
    );
  }
}

class _WatchNextCompactCard extends StatefulWidget {
  final WatchNextItem item;
  final WatchNextService service;
  final VoidCallback? onItemFocused;
  final FocusNode? focusNode;
  const _WatchNextCompactCard({super.key, required this.item, required this.service,
    this.onItemFocused, this.focusNode});

  @override
  State<_WatchNextCompactCard> createState() => _WatchNextCompactCardState();
}

class _WatchNextCompactCardState extends State<_WatchNextCompactCard> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.service.ensurePosterLoaded(widget.item.posterUri);
  }

  @override
  void didUpdateWidget(covariant _WatchNextCompactCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.posterUri != widget.item.posterUri) {
      widget.service.ensurePosterLoaded(widget.item.posterUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final poster = widget.service.getCachedPoster(widget.item.posterUri);
    return SizedBox(width: 222, child: Material(
      color: _focused ? const Color(0xFF425A79) : const Color(0xDD1B3049),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(13),
        side: BorderSide(color: _focused ? const Color(0xFFBEE9FF) : Colors.white24,
          width: _focused ? 2.5 : 1),
      ),
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
            child: Text(widget.item.source == 'plex' ? 'Plex  •  ${widget.item.title}' : widget.item.title, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white,
                fontWeight: FontWeight.w600, fontSize: 13))),
        ]),
      ),
    ));
  }
}
