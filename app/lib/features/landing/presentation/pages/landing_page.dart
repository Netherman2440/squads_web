import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  static const _maxWidth = 1200.0;
  static const _bg = Color(0xFF0F1411);
  static const _bgAlt = Color(0xFF141A16);
  static const _surface = Color(0xFF1A211C);
  static const _surfaceStrong = Color(0xFF202923);
  static const _accent = Color(0xFF81B64C);
  static const _accentSoft = Color(0xFFCBE8A8);
  static const _text = Color(0xFFE8F2E4);
  static const _muted = Color(0xFF9CA79C);

  final ScrollController _scrollController = ScrollController();
  int? _playersCount;
  int? _matchesCount;
  int? _rankingUpdatesCount;
  bool _statsAnimated = false;
  final _featuresKey = GlobalKey();
  final _howKey = GlobalKey();
  final _statsKey = GlobalKey();
  final _ctaKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollTo(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) {
      return;
    }
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _loadStats() async {
    final supabase = Supabase.instance.client;
    try {
      final results = await Future.wait<int>([
        supabase.from('players').count(),
        supabase.from('matches').count(),
        supabase.from('ranking_history').count(),
      ]);
      if (!mounted) {
        return;
      }
      setState(() {
        _playersCount = results[0];
        _matchesCount = results[1];
        _rankingUpdatesCount = results[2];
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final display = GoogleFonts.spaceGrotesk();
    final body = GoogleFonts.manrope();

    return Scaffold(
      body: Stack(
        children: [
          const _LandingBackground(),
          SafeArea(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  _buildNav(context),
                  _buildHero(context, display, body),
                  _buildValueProps(display, body),
                  _buildHowItWorks(display, body),
                  _buildFeatures(display, body),
                  _buildStats(display, body),
                  _buildCta(display, body),
                  _buildFooter(body),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNav(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 920;
        final items = [
          _NavLink(label: 'Funkcje', onTap: () => _scrollTo(_featuresKey)),
          _NavLink(label: 'Jak działa', onTap: () => _scrollTo(_howKey)),
          _NavLink(label: 'Liczby', onTap: () => _scrollTo(_statsKey)),
          _NavLink(label: 'Start', onTap: () => _scrollTo(_ctaKey)),
        ];

        return _section(
          child: isWide
              ? Row(
                  children: [
                    _brandMark(),
                    const Spacer(),
                    Row(
                      children: [
                        ...items,
                        const SizedBox(width: 16),
                        _secondaryButton(
                          label: 'Zaloguj',
                          onTap: () => context.go('/auth'),
                        ),
                        const SizedBox(width: 12),
                        _primaryButton(
                          label: 'Załóż konto',
                          onTap: () => context.go('/auth/register'),
                        ),
                      ],
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _brandMark(),
                    const SizedBox(height: 16),
                    Wrap(spacing: 16, runSpacing: 8, children: items),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      children: [
                        _secondaryButton(
                          label: 'Zaloguj',
                          onTap: () => context.go('/auth'),
                        ),
                        _primaryButton(
                          label: 'Załóż konto',
                          onTap: () => context.go('/auth/register'),
                        ),
                      ],
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildHero(BuildContext context, TextStyle display, TextStyle body) {
    return _revealSection(
      triggerOffset: 0.95,
      child: _section(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 980;
            final headingStyle = display.copyWith(
              fontSize: isWide ? 56 : 40,
              fontWeight: FontWeight.w700,
              color: _text,
              height: 1.05,
              letterSpacing: -1.5,
            );
            final leadStyle = body.copyWith(
              fontSize: isWide ? 20 : 18,
              color: _muted,
              height: 1.6,
            );

            final content = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Równe składy - szybko, dokładnie, bez kłopotów.',
                  style: headingStyle,
                ),
                const SizedBox(height: 20),
                Text.rich(
                  TextSpan(
                    style: leadStyle,
                    children: [
                      TextSpan(
                        text: 'pick',
                        style: leadStyle.copyWith(
                          color: _text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text: 'teams',
                        style: leadStyle.copyWith(
                          color: _accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text: '.pl',
                        style: leadStyle.copyWith(
                          color: _text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const TextSpan(
                        text:
                            ' to narzędzie dla organizatorów amatorskich meczów, '
                            'lig firmowych i ekip z orlika. Dodajesz graczy, '
                            'ustawiasz ich ranking i tworzysz mecz. Dostajesz ',
                      ),
                      TextSpan(
                        text: '20 zestawów',
                        style: leadStyle.copyWith(
                          color: _text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const TextSpan(text: ' wybranych z ponad '),
                      TextSpan(
                        text: '50 tysięcy',
                        style: leadStyle.copyWith(
                          color: _text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const TextSpan(
                        text:
                            ' układów, a po meczu algorytm uczy się dalej. '
                            'Wpisujesz wynik, a rankingi zawodników aktualizują się same.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _primaryButton(
                      label: 'Stwórz pierwszy skład',
                      onTap: () => context.go('/auth/register'),
                    ),
                    _secondaryButton(
                      label: 'Zobacz jak to działa',
                      onTap: () => _scrollTo(_howKey),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
              ],
            );

            return isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: content),
                      const SizedBox(width: 32),
                      const Expanded(child: _HeroPreview()),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      content,
                      const SizedBox(height: 36),
                      const _HeroPreview(),
                    ],
                  );
          },
        ),
      ),
    );
  }

  Widget _buildValueProps(TextStyle display, TextStyle body) {
    return _revealSection(
      child: _section(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                style: display.copyWith(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: _text,
                ),
                children: [
                  const TextSpan(text: 'Dlaczego pick'),
                  TextSpan(
                    text: 'teams',
                    style: TextStyle(color: _accent),
                  ),
                  const TextSpan(text: '.pl?'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Szkoda czasu na ręczne układanie. Chcesz mieć równe składy, '
              'szybki zapis wyników i ranking, który aktualizuje się sam.',
              style: body.copyWith(fontSize: 18, color: _muted),
            ),
            const SizedBox(height: 28),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 1000;
                const cards = [
                  _ValueCard(
                    title: 'Jeden zespół - wiele zastosowań',
                    description:
                        'Orlik, liga firmowa czy trening - wszystko w jednym miejscu.',
                    icon: Icons.groups_outlined,
                  ),
                  _ValueCard(
                    title: 'Uczciwsze mecze, mniej sporów',
                    description:
                        'Algorytm wyrównuje składy, a Ty oszczędzasz czas i nerwy.',
                    icon: Icons.handshake_outlined,
                  ),
                  _ValueCard(
                    title: 'Wpisujesz wynik, ranking się aktualizuje',
                    description:
                        'Po meczu zapisujesz rezultat i system koryguje oceny zawodników.',
                    icon: Icons.edit_note_outlined,
                  ),
                ];

                final benefitTiles = cards.map((card) {
                  final tile = Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: card,
                  );
                  if (!isWide) {
                    return tile;
                  }
                  return Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(width: 360, child: tile),
                  );
                }).toList();

                final benefitsColumn = Column(
                  crossAxisAlignment: isWide
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: benefitTiles,
                );

                return isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Expanded(child: _MatchHistoryPreview()),
                          const SizedBox(width: 28),
                          Expanded(child: benefitsColumn),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _MatchHistoryPreview(),
                          const SizedBox(height: 24),
                          benefitsColumn,
                        ],
                      );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHowItWorks(TextStyle display, TextStyle body) {
    return _revealSection(
      child: _section(
        key: _howKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Jak to działa',
              style: display.copyWith(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                color: _text,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Silnik draftu przeszukuje masę kombinacji i oddaje tylko te '
              'najbardziej równe.',
              style: body.copyWith(fontSize: 18, color: _muted),
            ),
            const SizedBox(height: 28),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 980;
                final steps = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _StepCard(
                      step: '01',
                      title: 'Tysiące kombinacji',
                      description:
                          'Algorytm sprawdza dziesiątki tysięcy wariantów, '
                          'także te '
                          'nieoczywiste.',
                    ),
                    SizedBox(height: 16),
                    _StepCard(
                      step: '02',
                      title: 'Balans to więcej niż suma',
                      description:
                          'Liczymy rozkład siły i odchylenie, żeby uniknąć '
                          'drużyny z jednym liderem.',
                    ),
                    SizedBox(height: 16),
                    _StepCard(
                      step: '03',
                      title: 'Dostosowania w tle',
                      description:
                          'Możesz zaznaczyć pozycje, formę i relacje między graczami, a algorytm '
                          'bierze je pod uwagę.',
                    ),
                  ],
                );

                final note = Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    'Wszystko w ułamkach sekund, dostępne zawsze gdy tego potrzebujesz.',
                    style: body.copyWith(
                      fontSize: 14,
                      color: _accentSoft,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );

                final left = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [steps, note],
                );

                return isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: left),
                          const SizedBox(width: 24),
                          const Expanded(child: _RankingPreview()),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          left,
                          const SizedBox(height: 24),
                          const _RankingPreview(),
                        ],
                      );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatures(TextStyle display, TextStyle body) {
    return _revealSection(
      child: _section(
        key: _featuresKey,
        background: _bgAlt,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Najważniejsze funkcje',
              style: display.copyWith(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                color: _text,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Wszystko, czego potrzeba do prowadzenia twoich rozgrywek.',
              style: body.copyWith(fontSize: 18, color: _muted),
            ),
            const SizedBox(height: 28),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: const [
                _FeatureCard(
                  title: 'Draft wielu zestawów meczy',
                  description: 'Top 20 propozycji gotowych do wybrania.',
                  icon: Icons.auto_fix_high_outlined,
                ),
                _FeatureCard(
                  title: 'Zrównoważone składy',
                  description:
                      'Balance score, rozkład siły i prawdopodobieństwo zwycięstwa zamiast czystej sumy.',
                  icon: Icons.balance_outlined,
                ),
                _FeatureCard(
                  title: 'Aktualizowane rankingi zawodnikow',
                  description:
                      'Po każdym meczu system uczy się nowych wyników.',
                  icon: Icons.trending_up_outlined,
                ),
                _FeatureCard(
                  title: 'Śledzenie wyników i statystyk',
                  description:
                      'Historia meczów, bilans i trend w jednym miejscu.',
                  icon: Icons.query_stats_outlined,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats(TextStyle display, TextStyle body) {
    return _revealSection(
      onReveal: () {
        if (!_statsAnimated) {
          setState(() => _statsAnimated = true);
        }
      },
      child: _section(
        key: _statsKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 880;
            final stats = [
              _StatTile(
                value: _playersCount,
                label: 'Aktualna liczba graczy',
                animate: _statsAnimated,
              ),
              _StatTile(
                value: _matchesCount,
                label: 'Liczba rozegranych meczy',
                animate: _statsAnimated,
              ),
              _StatTile(
                value: _rankingUpdatesCount,
                label: 'Liczba aktualizacji rankingów',
                animate: _statsAnimated,
              ),
            ];
            final tiles = List<Widget>.generate(
              stats.length,
              (index) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index == stats.length - 1 ? 0 : 16,
                  ),
                  child: stats[index],
                ),
              ),
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    style: display.copyWith(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      color: _text,
                    ),
                    children: [
                      const TextSpan(text: 'pick'),
                      TextSpan(
                        text: 'teams',
                        style: TextStyle(color: _accent),
                      ),
                      const TextSpan(text: '.pl w liczbach'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Aktualne dane pobierane bezposrednio z bazy.',
                  style: body.copyWith(fontSize: 18, color: _muted),
                ),
                const SizedBox(height: 28),
                isWide
                    ? Row(children: tiles)
                    : Column(
                        children: stats
                            .map(
                              (stat) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: stat,
                              ),
                            )
                            .toList(),
                      ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCta(TextStyle display, TextStyle body) {
    return _revealSection(
      child: _section(
        key: _ctaKey,
        background: _bgAlt,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A231B), Color(0xFF223025)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 760;
              final content = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gotowy na spokojny, uczciwy draft?',
                    style: display.copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: _text,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Stwórz skład, zapros znajomych i zacznij prowadzić '
                    'mecze z historią wyników.',
                    style: body.copyWith(fontSize: 18, color: _muted),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _primaryButton(
                        label: 'Załóż konto',
                        onTap: () => context.go('/auth/register'),
                      ),
                      _secondaryButton(
                        label: 'Zaloguj',
                        onTap: () => context.go('/auth'),
                      ),
                    ],
                  ),
                ],
              );

              return isWide
                  ? Row(
                      children: [
                        Expanded(child: content),
                        const SizedBox(width: 24),
                        const _CtaBadge(),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        content,
                        const SizedBox(height: 24),
                        const _CtaBadge(),
                      ],
                    );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(TextStyle body) {
    return _section(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'pickteams.pl - stworzony dla prowadzenia twoich rozgrywek.',
              style: body.copyWith(fontSize: 14, color: _muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section({Key? key, Color? background, required Widget child}) {
    return Container(
      key: key,
      width: double.infinity,
      color: background,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 72),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          child: child,
        ),
      ),
    );
  }

  Widget _revealSection({
    required Widget child,
    double triggerOffset = 0.85,
    VoidCallback? onReveal,
  }) {
    return _ScrollReveal(
      controller: _scrollController,
      triggerOffset: triggerOffset,
      onReveal: onReveal,
      child: child,
    );
  }

  Widget _brandMark() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _surfaceStrong,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Image.asset(
            'assets/icons/logo.png',
            width: 24,
            height: 24,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 12),
        Text.rich(
          TextSpan(
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _text,
            ),
            children: [
              const TextSpan(text: 'pick'),
              TextSpan(
                text: 'teams',
                style: TextStyle(color: _accent),
              ),
              const TextSpan(text: '.pl'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _primaryButton({required String label, required VoidCallback onTap}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: _accent,
        foregroundColor: _bg,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onTap,
      child: Text(
        label,
        style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _secondaryButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: _text,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onTap,
      child: Text(
        label,
        style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _LandingBackground extends StatelessWidget {
  const _LandingBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F1411), Color(0xFF141A16), Color(0xFF0F1411)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: const [
          _GlowCircle(
            alignment: Alignment(-0.9, -0.8),
            size: 320,
            colors: [Color(0xFF243428), Color(0x00000000)],
          ),
          _GlowCircle(
            alignment: Alignment(0.9, -0.6),
            size: 420,
            colors: [Color(0xFF2A3A2E), Color(0x00000000)],
          ),
          _GlowCircle(
            alignment: Alignment(0.0, 0.9),
            size: 520,
            colors: [Color(0xFF1F2C22), Color(0x00000000)],
          ),
          _GridOverlay(),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({
    required this.alignment,
    required this.size,
    required this.colors,
  });

  final Alignment alignment;
  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: colors),
        ),
      ),
    );
  }
}

class _GridOverlay extends StatelessWidget {
  const _GridOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _GridPainter(),
        size: MediaQuery.sizeOf(context),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1;
    const step = 120.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScrollReveal extends StatefulWidget {
  const _ScrollReveal({
    required this.child,
    required this.controller,
    this.triggerOffset = 0.85,
    this.onReveal,
  });

  final Widget child;
  final ScrollController controller;
  final double triggerOffset;
  final VoidCallback? onReveal;

  @override
  State<_ScrollReveal> createState() => _ScrollRevealState();
}

class _ScrollRevealState extends State<_ScrollReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(_fade);
    widget.controller.addListener(_checkVisibility);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
  }

  @override
  void didUpdateWidget(covariant _ScrollReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_checkVisibility);
      widget.controller.addListener(_checkVisibility);
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_checkVisibility);
    _controller.dispose();
    super.dispose();
  }

  void _checkVisibility() {
    if (_revealed || !mounted) {
      return;
    }
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) {
      return;
    }
    final offset = renderBox.localToGlobal(Offset.zero).dy;
    final height = MediaQuery.sizeOf(context).height;
    if (offset < height * widget.triggerOffset) {
      _revealed = true;
      _controller.forward();
      widget.onReveal?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: _LandingPageState._text,
        ),
      ),
    );
  }
}

class _ValueCard extends StatelessWidget {
  const _ValueCard({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _LandingPageState._surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _LandingPageState._surfaceStrong,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _LandingPageState._accent, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _LandingPageState._text,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: GoogleFonts.manrope(
              fontSize: 14,
              height: 1.5,
              color: _LandingPageState._muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchHistoryPreview extends StatelessWidget {
  const _MatchHistoryPreview();

  @override
  Widget build(BuildContext context) {
    const entries = [
      _MatchHistoryEntry(
        homeTeam: 'Fc Biali',
        awayTeam: 'Czarni United',
        homeColor: Color(0xFFFFFFFF),
        awayColor: Color(0xFF000000),
        subtitle: 'Dzisiejszy mecz',
        highlight: true,
      ),
      _MatchHistoryEntry(
        homeTeam: 'Orły Północy',
        awayTeam: 'Fc Biali',
        homeColor: Color(0xFF4FC3F7),
        awayColor: Color(0xFFFFFFFF),
        homeScore: 5,
        awayScore: 4,
        rankingDelta: -1.8,
      ),
      _MatchHistoryEntry(
        homeTeam: 'Fc Biali',
        awayTeam: 'City Strikers',
        homeColor: Color(0xFFFFFFFF),
        awayColor: Color(0xFF81B64C),
        homeScore: 6,
        awayScore: 2,
        rankingDelta: 2.7,
      ),
      _MatchHistoryEntry(
        homeTeam: 'Fc Biali',
        awayTeam: 'Niebiescy FC',
        homeColor: Color(0xFFFFFFFF),
        awayColor: Color(0xFF4FC3F7),
        homeScore: 3,
        awayScore: 3,
        rankingDelta: 0.4,
      ),
    ];

    final tiles = List<Widget>.generate(
      entries.length,
      (index) => Padding(
        padding: EdgeInsets.only(bottom: index == entries.length - 1 ? 0 : 12),
        child: _MatchHistoryTile(entry: entries[index]),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _LandingPageState._surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Twoje mecze',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _LandingPageState._text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Lista spotkań i zmiany w rankingu po każdym wyniku.',
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: _LandingPageState._muted,
            ),
          ),
          const SizedBox(height: 16),
          ...tiles,
        ],
      ),
    );
  }
}

class _MatchHistoryEntry {
  const _MatchHistoryEntry({
    required this.homeTeam,
    required this.awayTeam,
    required this.homeColor,
    required this.awayColor,
    this.homeScore,
    this.awayScore,
    this.rankingDelta,
    this.subtitle,
    this.highlight = false,
  });

  final String homeTeam;
  final String awayTeam;
  final Color homeColor;
  final Color awayColor;
  final int? homeScore;
  final int? awayScore;
  final double? rankingDelta;
  final String? subtitle;
  final bool highlight;
}

class _MatchHistoryTile extends StatelessWidget {
  const _MatchHistoryTile({required this.entry});

  final _MatchHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final hasScore = entry.homeScore != null && entry.awayScore != null;
    final delta = entry.rankingDelta;
    final deltaText = delta == null
        ? '--'
        : '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)}';
    final deltaColor = delta == null
        ? _LandingPageState._muted
        : (delta >= 0
              ? _LandingPageState._accentSoft
              : const Color(0xFFE06C5B));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: entry.highlight
            ? _LandingPageState._surfaceStrong
            : _LandingPageState._surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: entry.highlight
              ? _LandingPageState._accent.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: _InlineTeamLabel(
                        color: entry.homeColor,
                        name: entry.homeTeam,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '-',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _LandingPageState._muted,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: _InlineTeamLabel(
                        color: entry.awayColor,
                        name: entry.awayTeam,
                      ),
                    ),
                  ],
                ),
                if (entry.subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    entry.subtitle!,
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _LandingPageState._accentSoft,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MatchScoreBox(
                    score: hasScore ? '${entry.homeScore}' : '--',
                    highlight: entry.highlight,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    ':',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: _LandingPageState._muted,
                    ),
                  ),
                  const SizedBox(width: 6),
                  _MatchScoreBox(
                    score: hasScore ? '${entry.awayScore}' : '--',
                    highlight: entry.highlight,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                hasScore ? 'Ranking $deltaText' : 'Wpisz wynik',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: hasScore ? deltaColor : _LandingPageState._accentSoft,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InlineTeamLabel extends StatelessWidget {
  const _InlineTeamLabel({required this.color, required this.name});

  final Color color;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            name,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _LandingPageState._text,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _MatchScoreBox extends StatelessWidget {
  const _MatchScoreBox({required this.score, required this.highlight});

  final String score;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: highlight
            ? _LandingPageState._surfaceStrong
            : _LandingPageState._surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.white.withValues(alpha: highlight ? 0.2 : 0.12),
        ),
      ),
      child: Text(
        score,
        style: GoogleFonts.manrope(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: _LandingPageState._text,
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.step,
    required this.title,
    required this.description,
  });

  final String step;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _LandingPageState._surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            step,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _LandingPageState._accentSoft,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _LandingPageState._text,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: GoogleFonts.manrope(
              fontSize: 14,
              height: 1.5,
              color: _LandingPageState._muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _LandingPageState._surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _LandingPageState._accent, size: 22),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _LandingPageState._text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: GoogleFonts.manrope(
              fontSize: 13,
              height: 1.5,
              color: _LandingPageState._muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _RankingPreview extends StatelessWidget {
  const _RankingPreview();

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[
      const FlSpot(0, 68),
      const FlSpot(1, 23),
      const FlSpot(2, 32),
      const FlSpot(3, 70),
      const FlSpot(4, 78),
      const FlSpot(5, 84),
      const FlSpot(6, 83),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _LandingPageState._surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Kuba',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _LandingPageState._text,
                ),
              ),
              const Spacer(),
              Text(
                'Ranking: 83',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _LandingPageState._accentSoft,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 100,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 10,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white.withValues(alpha: 0.08),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: const FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: false,
                    color: _LandingPageState._accentSoft,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: _LandingPageState._accentSoft.withValues(
                        alpha: 0.12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Ranking reaguje na wyniki i stabilizuje sie z czasem.',
            style: GoogleFonts.manrope(
              fontSize: 13,
              color: _LandingPageState._muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.label,
    required this.animate,
  });

  final int? value;
  final String label;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _LandingPageState._surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AnimatedCount(
            value: value,
            animate: animate,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: _LandingPageState._accentSoft,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: _LandingPageState._muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedCount extends StatelessWidget {
  const _AnimatedCount({
    required this.value,
    required this.animate,
    required this.style,
  });

  final int? value;
  final bool animate;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.decimalPattern('pl');
    if (value == null) {
      return Text('--', style: style);
    }

    if (!animate) {
      return Text('0', style: style);
    }

    return TweenAnimationBuilder<double>(
      key: ValueKey('count-$value-$animate'),
      tween: Tween<double>(begin: 0, end: value!.toDouble()),
      duration: const Duration(milliseconds: 1400),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        return Text(formatter.format(animatedValue.round()), style: style);
      },
    );
  }
}

class _HeroPreview extends StatelessWidget {
  const _HeroPreview();

  @override
  Widget build(BuildContext context) {
    const homePlayers = [
      _PlayerPreview(name: 'Adam', base: 79, ranking: 90.35, delta: 11.35),
      _PlayerPreview(name: 'Robert', base: 65, ranking: 65.00),
      _PlayerPreview(name: 'Filip', base: 52, ranking: 55.17, delta: 3.17),
      _PlayerPreview(name: 'Michal', base: 62, ranking: 55.00, delta: -7.00),
      _PlayerPreview(
        name: 'Krzysztof',
        base: 50,
        ranking: 35.45,
        delta: -14.55,
      ),
    ];

    const awayPlayers = [
      _PlayerPreview(name: 'Tomasz', base: 83, ranking: 82.21, delta: -0.79),
      _PlayerPreview(name: 'Pawel', base: 71, ranking: 71.00),
      _PlayerPreview(name: 'Kamil', base: 54, ranking: 69.74, delta: 15.74),
      _PlayerPreview(name: 'Mateusz', base: 50, ranking: 50.00),
      _PlayerPreview(name: 'Bartek', base: 28, ranking: 28.00),
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _LandingPageState._surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Opcja 1 z 20',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _LandingPageState._accentSoft,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: _LandingPageState._text,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(
                child: _TeamColumn(
                  title: 'Home',
                  totalRanking: 301.0,
                  players: homePlayers,
                  accent: Color(0xFF81B64C),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _TeamColumn(
                  title: 'Away',
                  totalRanking: 300.9,
                  players: awayPlayers,
                  accent: Color(0xFF6FB0D6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _WinProbabilityBar(homeProbability: 0.5),
        ],
      ),
    );
  }
}

class _TeamColumn extends StatelessWidget {
  const _TeamColumn({
    required this.title,
    required this.totalRanking,
    required this.players,
    required this.accent,
  });

  final String title;
  final double totalRanking;
  final List<_PlayerPreview> players;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _LandingPageState._surfaceStrong,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
              const Spacer(),
              Text(
                'Ranking: ${totalRanking.toStringAsFixed(1)}',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _LandingPageState._muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...players.map(
            (player) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PlayerTile(player: player, accent: accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerPreview {
  const _PlayerPreview({
    required this.name,
    required this.base,
    required this.ranking,
    this.delta,
  });

  final String name;
  final double base;
  final double ranking;
  final double? delta;
}

class _PlayerTile extends StatelessWidget {
  const _PlayerTile({required this.player, required this.accent});

  final _PlayerPreview player;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final delta = player.delta;
    final deltaColor = delta == null
        ? _LandingPageState._muted
        : (delta >= 0
              ? _LandingPageState._accentSoft
              : const Color(0xFFE06C5B));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Text(
            player.name.substring(0, 1).toUpperCase(),
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                player.name,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _LandingPageState._text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Base: ${player.base.toStringAsFixed(0)}  ·  '
                'Ranking: ${player.ranking.toStringAsFixed(2)}',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  color: _LandingPageState._muted,
                ),
              ),
            ],
          ),
        ),
        if (delta != null)
          Text(
            '${delta > 0 ? '+' : ''}${delta.toStringAsFixed(2)}',
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: deltaColor,
            ),
          ),
      ],
    );
  }
}

class _WinProbabilityBar extends StatelessWidget {
  const _WinProbabilityBar({required this.homeProbability});

  final double homeProbability;

  @override
  Widget build(BuildContext context) {
    final awayProbability = 1 - homeProbability;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _LandingPageState._surfaceStrong,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Prawdopodobieństwo wygranej',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _LandingPageState._text,
                ),
              ),
              const Spacer(),
              Text(
                '${(homeProbability * 100).round()}% / '
                '${(awayProbability * 100).round()}%',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _LandingPageState._accentSoft,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  Expanded(
                    flex: (homeProbability * 100).round(),
                    child: Container(color: _LandingPageState._accent),
                  ),
                  Expanded(
                    flex: (awayProbability * 100).round(),
                    child: Container(color: _LandingPageState._accentSoft),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CtaBadge extends StatelessWidget {
  const _CtaBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _LandingPageState._surfaceStrong,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tryb gościa',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _LandingPageState._text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Zobacz publiczne składy bez konta.',
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: _LandingPageState._muted,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: _LandingPageState._text,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => context.go('/auth'),
            child: Text(
              'Wejdź jako gość',
              style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
