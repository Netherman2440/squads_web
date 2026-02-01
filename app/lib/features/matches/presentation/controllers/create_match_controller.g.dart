// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_match_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CreateMatchController)
const createMatchControllerProvider = CreateMatchControllerProvider._();

final class CreateMatchControllerProvider
    extends
        $NotifierProvider<CreateMatchController, AsyncValue<MatchDetailsDto?>> {
  const CreateMatchControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'createMatchControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$createMatchControllerHash();

  @$internal
  @override
  CreateMatchController create() => CreateMatchController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<MatchDetailsDto?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<MatchDetailsDto?>>(value),
    );
  }
}

String _$createMatchControllerHash() =>
    r'55cf00c2f1578e532800c543157ddfc48fa5df50';

abstract class _$CreateMatchController
    extends $Notifier<AsyncValue<MatchDetailsDto?>> {
  AsyncValue<MatchDetailsDto?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref
            as $Ref<AsyncValue<MatchDetailsDto?>, AsyncValue<MatchDetailsDto?>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<MatchDetailsDto?>,
                AsyncValue<MatchDetailsDto?>
              >,
              AsyncValue<MatchDetailsDto?>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
