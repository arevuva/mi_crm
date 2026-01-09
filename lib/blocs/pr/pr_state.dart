import 'package:equatable/equatable.dart';

import '../../data/models/pr_asset.dart';
import '../../data/models/smm_post.dart';

class PrState extends Equatable {
  final bool loading;
  final List<PrAsset> assets;
  final List<SmmPost> posts;
  final String? error;

  const PrState({required this.loading, this.assets = const [], this.posts = const [], this.error});

  factory PrState.initial() => const PrState(loading: false);

  PrState copyWith({bool? loading, List<PrAsset>? assets, List<SmmPost>? posts, String? error}) {
    return PrState(
      loading: loading ?? this.loading,
      assets: assets ?? this.assets,
      posts: posts ?? this.posts,
      error: error,
    );
  }

  @override
  List<Object?> get props => [loading, assets, posts, error];
}
