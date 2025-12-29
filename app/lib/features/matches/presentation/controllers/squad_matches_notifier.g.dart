// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'squad_matches_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SquadMatchesNotifier)
const squadMatchesProvider = SquadMatchesNotifierFamily._();

final class SquadMatchesNotifierProvider
    extends $NotifierProvider<SquadMatchesNotifier, AsyncValue<List<Match>>> {
  const SquadMatchesNotifierProvider._({
    required SquadMatchesNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'squadMatchesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$squadMatchesNotifierHash();

  @override
  String toString() {
    return r'squadMatchesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SquadMatchesNotifier create() => SquadMatchesNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<Match>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<List<Match>>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SquadMatchesNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$squadMatchesNotifierHash() =>
    r'6e93d504e7f05aae571b47ed9bd2fa29c7727aac';

final class SquadMatchesNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          SquadMatchesNotifier,
          AsyncValue<List<Match>>,
          AsyncValue<List<Match>>,
          AsyncValue<List<Match>>,
          String
        > {
  const SquadMatchesNotifierFamily._()
    : super(
        retry: null,
        name: r'squadMatchesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SquadMatchesNotifierProvider call(String squadId) =>
      SquadMatchesNotifierProvider._(argument: squadId, from: this);

  @override
  String toString() => r'squadMatchesProvider';
}

abstract class _$SquadMatchesNotifier
    extends $Notifier<AsyncValue<List<Match>>> {
  late final _$args = ref.$arg as String;
  String get squadId => _$args;

  AsyncValue<List<Match>> build(String squadId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref =
        this.ref as $Ref<AsyncValue<List<Match>>, AsyncValue<List<Match>>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Match>>, AsyncValue<List<Match>>>,
              AsyncValue<List<Match>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
