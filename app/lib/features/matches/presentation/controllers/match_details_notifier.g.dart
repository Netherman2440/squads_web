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
    extends
        $NotifierProvider<MatchDetailsNotifier, AsyncValue<MatchDetailsDto>> {
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
  Override overrideWithValue(AsyncValue<MatchDetailsDto> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<MatchDetailsDto>>(value),
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
    r'572ca14900b301c200ebdfedf7fd64c59e6eb555';

final class MatchDetailsNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          MatchDetailsNotifier,
          AsyncValue<MatchDetailsDto>,
          AsyncValue<MatchDetailsDto>,
          AsyncValue<MatchDetailsDto>,
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

abstract class _$MatchDetailsNotifier
    extends $Notifier<AsyncValue<MatchDetailsDto>> {
  late final _$args = ref.$arg as String;
  String get matchId => _$args;

  AsyncValue<MatchDetailsDto> build(String matchId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref =
        this.ref
            as $Ref<AsyncValue<MatchDetailsDto>, AsyncValue<MatchDetailsDto>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<MatchDetailsDto>,
                AsyncValue<MatchDetailsDto>
              >,
              AsyncValue<MatchDetailsDto>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
