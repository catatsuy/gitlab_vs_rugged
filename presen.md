## grit 特徴

 * Git のオブジェクトファイルや，git のコマンドの実行結果をゴリゴリやっている
   * 子プロセスの起動など，かなり遅そう
 * ドキュメントが貧弱
   * ソースコードを読む必要がある
 * Ruby 実装で簡単にいじれるので Fork が多い
 * GitLab が使っているのは Fork（今回使用するのはこれ）
 * GitHub 本家も Fork してる（最近更新はない）


## rugged 特徴

 * libgit2 の Ruby バインディング
   * libgit2 は C 実装で git の再実装に近い
   * 高速であることが期待できる
 * GitHub も使っているみたい
 * C の API をバインディングしているだけなのでメソッド呼び出しなどの API 設計があまりイケてない
 * C 実装なので簡単にいじれず，Fork も少ない（スターは多い）
 * libgit2 に関するドキュメントは充実
   * rugged は少ない

## URL

 * [gitlabhq/grit](https://github.com/gitlabhq/grit)
 * [libgit2/rugged](https://github.com/libgit2/rugged)
 * [libgit2](http://libgit2.github.com/)
 * [libgit2 API](http://libgit2.github.com/libgit2/#HEAD)


## grit 仕様

 * grit で diff を取るとき子プロセスを立ち上げて git のコマンドを叩く
   * かなり遅い
   * GitLab で時折詰まったように感じるのはここ！
 * grit だと大きすぎる diff は取れない
   * `Grit::Git.git_max_size` がデフォルト 5MB でこれを大きくすると大丈夫だが，標準出力が大きくなるとかなり時間がかかる
   * GitLab なら `gitlab.yml` の `git: max_size` を変更すると変更できる


## ベンチマーク

 * grit はメソッドによっては子プロセスを呼び出す
   * ruby 標準搭載の `Benchmark.benchmark` はデフォルトで子プロセスの実行時間を出力しない
   * 引数を渡して表示できるようにする
