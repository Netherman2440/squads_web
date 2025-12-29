// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_details_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MatchDetailsNotifier)
const matchDetailsProvider = MatchDetailsNotifierFamily._();

final class MatchDetailsNotifierProvider
    extends $NotifierProvider<MatchDetailsNotifier, AsyncValue<Match>> {
  const MatchDetailsNotifierProvider._({
    required MatchDetailsNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'matchDetailsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$matchDetailsNotifierHash();

  @override
  String toString() {
    return r'matchDetailsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  MatchDetailsNotifier create() => MatchDetailsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<Match> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<Match>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MatchDetailsNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$matchDetailsNotifierHash() =>
    r'b865a442ac73f5ca5a9cb6e51a047575043365af';

final class MatchDetailsNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          MatchDetailsNotifier,
          AsyncValue<Match>,
          AsyncValue<Match>,
          AsyncValue<Match>,
          String
        > {
  const MatchDetailsNotifierFamily._()
    : super(
        retry: null,
        name: r'matchDetailsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MatchDetailsNotifierProvider call(String matchId) =>
      MatchDetailsNotifierProvider._(argument: matchId, from: this);

  @override
  String toString() => r'matchDetailsProvider';
}

abstract class _$MatchDetailsNotifier extends $Notifier<AsyncValue<Match>> {
  late final _$args = ref.$arg as String;
  String get matchId => _$args;

  AsyncValue<Match> build(String matchId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref = this.ref as $Ref<AsyncValue<Match>, AsyncValue<Match>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Match>, AsyncValue<Match>>,
              AsyncValue<Match>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
