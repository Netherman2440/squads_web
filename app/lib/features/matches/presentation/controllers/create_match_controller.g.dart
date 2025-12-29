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
    extends $NotifierProvider<CreateMatchController, AsyncValue<Match?>> {
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
  Override overrideWithValue(AsyncValue<Match?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<Match?>>(value),
    );
  }
}

String _$createMatchControllerHash() =>
    r'55cf00c2f1578e532800c543157ddfc48fa5df50';

abstract class _$CreateMatchController extends $Notifier<AsyncValue<Match?>> {
  AsyncValue<Match?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<Match?>, AsyncValue<Match?>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Match?>, AsyncValue<Match?>>,
              AsyncValue<Match?>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
