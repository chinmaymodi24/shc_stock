part of 'analytics_charts.dart';

/// "Top Selling Products" / "Top Clients by Revenue": the label and its value
/// on one line, with a proportional bar underneath. Bars are scaled against
/// the leader, so the first row always fills the track.
class RankedBarList extends StatefulWidget {
  final List<RankedRow> rows;

  const RankedBarList({super.key, required this.rows});

  @override
  State<RankedBarList> createState() => _RankedBarListState();
}

class _RankedBarListState extends State<RankedBarList> {
  final RxInt _hovered = (-1).obs;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    if (widget.rows.isEmpty) {
      return Center(
        child: Text(
          'No sales recorded yet',
          style: TextStyle(
            fontSize: 12.5,
            color: colors.textHint,
            fontFamily: brandFontFamily,
          ),
        ),
      );
    }

    final palette = analyticsPalette(context);
    final max = widget.rows
        .map((r) => r.value)
        .fold<double>(0, (a, b) => a > b ? a : b);

    return Obx(() {
      final hovered = _hovered.value;
      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var i = 0; i < widget.rows.length; i++)
            MouseRegion(
              onEnter: (_) => _hovered.value = i,
              onExit: (_) {
                if (_hovered.value == i) _hovered.value = -1;
              },
              child: _row(
                context,
                widget.rows[i],
                palette[i % palette.length],
                max,
                hovered >= 0 && hovered != i,
              ),
            ),
        ],
      );
    });
  }

  Widget _row(
    BuildContext context,
    RankedRow row,
    Color color,
    double max,
    bool dimmed,
  ) {
    final colors = context.appColors;
    final fraction = max == 0 ? 0.0 : (row.value / max).clamp(0.02, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  row.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: dimmed ? colors.textSecondary : colors.textPrimary,
                    fontFamily: brandFontFamily,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                row.display,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: dimmed ? colors.textSecondary : colors.textPrimary,
                  fontFamily: brandFontFamily,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LayoutBuilder(
            builder: (context, constraints) => Stack(
              children: [
                Container(
                  height: 7,
                  decoration: BoxDecoration(
                    color: colors.divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: 7,
                  width: constraints.maxWidth * fraction,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: dimmed ? 0.45 : 1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Payment collection ───────────────────────────────────────────────────────

/// Half-ring gauge with the percentage in the middle. A single figure with no
/// series to compare, so it carries its readout permanently instead of on
/// hover.
class HalfGauge extends StatelessWidget {
  final double percent;
  final Color color;
  final double size;

  const HalfGauge({
    super.key,
    required this.percent,
    required this.color,
    this.size = 150,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SizedBox(
      width: size,
      // A half ring only needs a little over half the width in height, plus
      // room for the number sitting inside it.
      height: size * 0.62,
      child: CustomPaint(
        painter: _GaugePainter(
          percent: percent.clamp(0, 100).toDouble(),
          color: color,
          trackColor: colors.divider,
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.only(top: size * 0.14),
            child: Text(
              '${percent.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
                fontFamily: brandFontFamily,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double percent;
  final Color color;
  final Color trackColor;

  _GaugePainter({
    required this.percent,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 14.0;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.width - stroke,
    );

    final track = Paint()
      ..color = trackColor
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final value = Paint()
      ..color = color
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawArc(rect, math.pi, math.pi, false, track);
    canvas.drawArc(rect, math.pi, math.pi * (percent / 100), false, value);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.percent != percent ||
      old.color != color ||
      old.trackColor != trackColor;
}

// ── Receivables aging ────────────────────────────────────────────────────────

/// One horizontal bar split by share, each segment labelled with its own
/// percentage. Hovering a segment reads out the rupee amount behind it.
class StackedShareBar extends StatefulWidget {
  final List<AgingBucket> buckets;
  final List<Color> colors;
  final double height;

  const StackedShareBar({
    super.key,
    required this.buckets,
    required this.colors,
    this.height = 28,
  });

  @override
  State<StackedShareBar> createState() => _StackedShareBarState();
}

class _StackedShareBarState extends State<StackedShareBar> {
  final RxInt _hovered = (-1).obs;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final total = widget.buckets.fold<double>(0, (s, b) => s + b.amount);

    if (total <= 0) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: colors.divider,
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: Text(
          'Nothing outstanding',
          style: TextStyle(
            fontSize: 11.5,
            color: colors.textSecondary,
            fontFamily: brandFontFamily,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) => Obx(() {
        final hovered = _hovered.value;
        return SizedBox(
          height: widget.height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Row(
                  children: [
                    for (var i = 0; i < widget.buckets.length; i++)
                      if (widget.buckets[i].amount > 0)
                        Expanded(
                          flex: math.max(
                            (widget.buckets[i].amount / total * 1000).round(),
                            1,
                          ),
                          child: _segment(context, i, total, hovered),
                        ),
                  ],
                ),
              ),
              if (hovered >= 0) _tooltip(hovered, total, constraints.maxWidth),
            ],
          ),
        );
      }),
    );
  }

  Widget _segment(BuildContext context, int i, double total, int hovered) {
    final bucket = widget.buckets[i];
    final color = widget.colors[i % widget.colors.length];
    final dimmed = hovered >= 0 && hovered != i;
    final share = bucket.amount / total * 100;

    return MouseRegion(
      onEnter: (_) => _hovered.value = i,
      onExit: (_) {
        if (_hovered.value == i) _hovered.value = -1;
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _hovered.value = _hovered.value == i ? -1 : i,
        child: Container(
          height: widget.height,
          color: color.withValues(alpha: dimmed ? 0.45 : 1),
          alignment: Alignment.center,
          child: Text(
            '${share.toStringAsFixed(0)}%',
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontFamily: brandFontFamily,
            ),
          ),
        ),
      ),
    );
  }

  Widget _tooltip(int i, double total, double width) {
    // Centre of the hovered segment: everything before it, plus half of it.
    var before = 0.0;
    for (var j = 0; j < i; j++) {
      before += widget.buckets[j].amount;
    }
    final centre = ((before + widget.buckets[i].amount / 2) / total) * width;

    return Positioned(
      left: (centre - ChartTooltip.width / 2)
          .clamp(0.0, math.max(width - ChartTooltip.width, 0.0))
          .toDouble(),
      top: -ChartTooltip.height - 8,
      child: ChartTooltip(
        label: widget.buckets[i].label,
        value: formatRupees(widget.buckets[i].amount),
        accent: widget.colors[i % widget.colors.length],
      ),
    );
  }
}

// ── Revenue by category ──────────────────────────────────────────────────────

/// Squarified treemap: tile area is the category's share of revenue. Tiles too
/// small to hold their caption still read out on hover.
class RevenueTreemap extends StatefulWidget {
  final List<CategoryRevenue> rows;

  const RevenueTreemap({super.key, required this.rows});

  @override
  State<RevenueTreemap> createState() => _RevenueTreemapState();
}

class _RevenueTreemapState extends State<RevenueTreemap> {
  final RxInt _hovered = (-1).obs;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final rows = widget.rows.where((r) => r.amount > 0).toList();
    if (rows.isEmpty) {
      return Center(
        child: Text(
          'No categorised revenue yet',
          style: TextStyle(
            fontSize: 12.5,
            color: colors.textHint,
            fontFamily: brandFontFamily,
          ),
        ),
      );
    }

    final palette = analyticsPalette(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final rects = squarify(
          rows.map((r) => r.amount).toList(),
          Rect.fromLTWH(0, 0, constraints.maxWidth, constraints.maxHeight),
        );
        return Obx(() {
          final hovered = _hovered.value;
          return Stack(
            children: [
              for (var i = 0; i < rows.length; i++)
                Positioned.fromRect(
                  rect: rects[i].deflate(1.5),
                  child: _tile(
                    context,
                    i,
                    rows[i],
                    palette[i % palette.length],
                    rects[i],
                    hovered,
                  ),
                ),
            ],
          );
        });
      },
    );
  }

  Widget _tile(
    BuildContext context,
    int i,
    CategoryRevenue row,
    Color color,
    Rect rect,
    int hovered,
  ) {
    final dimmed = hovered >= 0 && hovered != i;
    // Captions are fitted to the tile, not the other way round: a big tile
    // carries name + amount + share, a middle one drops to a single-line name
    // and its amount, and a sliver carries nothing at all. Every tile still
    // reads out in full on hover.
    final detail = rect.height >= 96 && rect.width >= 100
        ? _TileDetail.full
        : (rect.height >= 62 && rect.width >= 74
              ? _TileDetail.brief
              : _TileDetail.none);

    return MouseRegion(
      onEnter: (_) => _hovered.value = i,
      onExit: (_) {
        if (_hovered.value == i) _hovered.value = -1;
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _hovered.value = _hovered.value == i ? -1 : i,
        child: Tooltip(
          message:
              '${row.category} · ${formatRupees(row.amount)} · '
              '${row.percent.toStringAsFixed(0)}%',
          waitDuration: const Duration(milliseconds: 250),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            decoration: BoxDecoration(
              color: color.withValues(alpha: dimmed ? 0.55 : 1),
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.all(10),
            alignment: Alignment.bottomLeft,
            child: detail == _TileDetail.none
                ? const SizedBox.shrink()
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.category,
                        maxLines: detail == _TileDetail.full ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.25,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontFamily: brandFontFamily,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatRupeesCompact(row.amount),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.25,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontFamily: brandFontFamily,
                        ),
                      ),
                      if (detail == _TileDetail.full)
                        Text(
                          '${row.percent.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 10.5,
                            height: 1.25,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.85),
                            fontFamily: brandFontFamily,
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// How much of a treemap tile's caption fits inside it.
enum _TileDetail { full, brief, none }

/// Squarified treemap layout — lays [values] out in [container] keeping tiles
/// as close to square as it can, which is what makes their areas comparable.
///
/// Public so the layout can be exercised on its own; the algorithm is the
/// standard Bruls/Huizing/van Wijk one.
List<Rect> squarify(List<double> values, Rect container) {
  final out = List<Rect>.filled(values.length, Rect.zero);
  final total = values.fold<double>(0, (a, b) => a + b);
  if (total <= 0 || container.width <= 0 || container.height <= 0) return out;

  // Work in pixel areas so a row's thickness is just area / length.
  final scale = (container.width * container.height) / total;
  final areas = values.map((v) => v * scale).toList();

  var free = container;
  var i = 0;
  while (i < areas.length) {
    final short = math.min(free.width, free.height);
    var end = i;
    var sum = areas[i];
    var best = _worstRatio(areas, i, i, sum, short);

    // Grow the row while doing so makes its worst tile squarer.
    while (end + 1 < areas.length) {
      final nextSum = sum + areas[end + 1];
      final nextWorst = _worstRatio(areas, i, end + 1, nextSum, short);
      if (nextWorst > best) break;
      end++;
      sum = nextSum;
      best = nextWorst;
    }

    if (free.width >= free.height) {
      final colWidth = sum / free.height;
      var y = free.top;
      for (var k = i; k <= end; k++) {
        final h = areas[k] / colWidth;
        out[k] = Rect.fromLTWH(free.left, y, colWidth, h);
        y += h;
      }
      free = Rect.fromLTRB(
        free.left + colWidth,
        free.top,
        free.right,
        free.bottom,
      );
    } else {
      final rowHeight = sum / free.width;
      var x = free.left;
      for (var k = i; k <= end; k++) {
        final w = areas[k] / rowHeight;
        out[k] = Rect.fromLTWH(x, free.top, w, rowHeight);
        x += w;
      }
      free = Rect.fromLTRB(
        free.left,
        free.top + rowHeight,
        free.right,
        free.bottom,
      );
    }

    i = end + 1;
  }
  return out;
}

/// Worst (furthest from 1) aspect ratio in the run areas[from..to].
double _worstRatio(
  List<double> areas,
  int from,
  int to,
  double sum,
  double side,
) {
  if (sum <= 0 || side <= 0) return double.infinity;
  var max = areas[from];
  var min = areas[from];
  for (var i = from + 1; i <= to; i++) {
    max = math.max(max, areas[i]);
    min = math.min(min, areas[i]);
  }
  if (min <= 0) return double.infinity;
  final s2 = sum * sum;
  final w2 = side * side;
  return math.max((w2 * max) / s2, s2 / (w2 * min));
}
