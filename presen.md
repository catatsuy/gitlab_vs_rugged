# git を高速に扱うためにどうすればいいのか調べた

まかいぞーしようとしたけど結局無理だったので今回得られた知見紹介

## grit 特徴

 * Git のオブジェクトファイルや，git のコマンドの実行結果をゴリゴリやっている
   * 子プロセスの起動したり，ファイルをパースしたり…
 * ドキュメントが貧弱
   * ソースコードを読む必要がある
   * 昔からあるライブラリで，似たようなメソッドが複数あるなど一貫性がない
   * ソースコードもあまり綺麗でなく，メンテナンスをする気がある人があまりいない印象
 * Ruby 実装で簡単にいじれるので Fork が多い
 * GitLab が使っているのは Fork（今回使用するのはこれ）
 * GitHub 本家も Fork してる（最近更新はない）


## rugged 特徴

 * libgit2 の Ruby バインディング
   * libgit2 は C 実装で git の再実装に近い
 * GitHub も使っているらしい
 * C の API をバインディングしているだけなので git の実装がかなり生で出ている
   * git の内部の知識がないと使うのが難しい
   * コマンドラインの使い方しか知らない人には使いにくい
 * C 実装だからか，Fork は少ない（スターは多い）
 * rugged に関するドキュメントは少ない
   * libgit2 はある
 * 将来的には GitLab も使いたいらしい（本気度は不明）
   * [Migrate to libgit2 · Issue #3379 · gitlabhq/gitlabhq](https://github.com/gitlabhq/gitlabhq/issues/3379)


## grit vs rugged

|      gem       |    grit   |    rugged   |
|----------------|:---------:|:-----------:|
| implementation | pure ruby | C extension |
| service        |  GitLab   |   Github    |
| speed          |   slow    | high speed  |
| document       |  little   |   little    |



## grit 仕様

 * grit で diff を取るとき子プロセスを立ち上げて git のコマンドを叩く
   * かなり遅いはず
   * GitLab で時折詰まったように感じるのはここ
 * コミット一覧はログからゴリゴリやる
   * Ruby だと文字列操作や配列の末尾に要素追加などは遅い
 * grit だと大きすぎる diff は取れない
   * `Grit::Git.git_max_size` がデフォルト 5MB でこれを大きくすると大丈夫だが，標準出力が大きくなるとかなり時間がかかる
   * GitLab なら `gitlab.yml` の `git: max_size` を変更する


## ベンチマーク

 * grit はメソッドによっては子プロセスを呼び出す
   * ruby 標準搭載の `Benchmark.benchmark` はデフォルトで子プロセスの実行時間を出力しない
   * 引数を渡して表示できるようにする


## ベンチ結果

                          user     system         cu         cs      total       real
    [rugged] diff     0.420000   0.010000   0.000000   0.000000   0.430000 (  0.426980)
    [grit] diff       4.720000   0.400000   7.120000   1.210000  13.450000 ( 12.906260)
    [rugged] commit   0.000000   0.000000   0.000000   0.000000   0.000000 (  0.004854)
    [grit] commit     1.210000   0.060000   0.000000   0.000000   1.270000 (  1.533623)


## grit/GitLab バグ

 * GitLab 周辺の gem は gem として登録されているにも関わらず GitLab 以外から使用することを一切考慮していない
 * 単体で読み込もうとするとバグに悩まされることになる
 * 自分が遭遇したバグ紹介


## [gitlab_git] GitLab から使うことしか考えていない

 * gitlab_git が GitLab で git を実際に触る部分
   * grit を使うのはここ
 * GitLab は ActiveSupport が読み込まれるが，gitlab_git は独立した gem なので使うなら読み込む必要
   * しかし一部しか読み込んでいなかった
   * 具体的には `try` を使用していた
 * プルリク出した
   * 取り込まれない
   * [Pull Request #22 · gitlabhq/gitlab_git](https://github.com/gitlabhq/gitlab_git/pull/22)


## [grit] require できない #1

 * Gemfile から `path:` 指定で読み込むと require できない
   * `VERSION` ファイルのパスが間違えていて起動できていない
   * すでにプルリクが出ている
   * 何ヶ月も取り込まれず放置されていた
   * マージしてもらえるように催促コメントする
   * マージしてもらえた！！
   * 今回のベンチマークにはもちろんこのパッチを適用
   * [Fixed issue #32 · Pull Request #35 · gitlabhq/grit](https://github.com/gitlabhq/grit/pull/35)


## いい話

<table>
<tr>
<td><img src="http://gyazo.com/c67eb6acbd697654955aa0586daaed8f.png"></td>
<td><img src="http://gyazo.com/5a7ebb96ef727e593c72deb37a62d66e.png"></td>
</tr>
</table>


## [grit] 想定外のコミット #2

 * ある commit が読み込めない
   * オブジェクトファイルが想定外の形式らしい
   * 正しい挙動が不明なため issue 登録
   * [Issue #37 · gitlabhq/grit](https://github.com/gitlabhq/grit/issues/37)
   * git のファイルを改行などからパースをしているだけの実装なので解析結果がおかしくなることはよくありそう


## [grit] 偽りのコメントアウト #3

 * コメントアウトに嘘があった
   * `git.rev_list` を呼ぶと `method_missing` になると書いてあったが，実際は include したクラスに実装があった
   * プルリクしたが反応がない
   * どれも古くからあるコードで何が想定された動きだったのかわからない
   * `method_missing` の方にしても動きそうだったが，テストは通らない
   * [Pull Request #38 · gitlabhq/grit](https://github.com/gitlabhq/grit/pull/38)


## まとめ

 * GitLab を高速化できないのか模索したら grit を rugged に書き換えればいいのでは？という仮説ができた
 * ベンチマークを取って比較しようとしたが grit とか GitLab 周辺の gem がバギーすぎて大変だった
 * プルリクも出したりしたが，取り込まれることはあまりないみたい
 * ドキュメントもないのでソースコードを読む必要があって大変だった
 * ベンチマークを取ったはいいものの rugged が速すぎて比較にならなかった
 * 書き換えるためには rugged のメソッドをよく把握する必要があるので面倒そう


## URL

 * [Git - Git Objects](http://git-scm.com/book/en/Git-Internals-Git-Objects)
 * [Git - Git References](http://git-scm.com/book/en/Git-Internals-Git-References)
 * [Ruby - BundlerでC拡張を含んだgemを公開する - Qiita](http://qiita.com/gam0022/items/2ee82e84e5c9f608eb85)
 * [gitlabhq/grit](https://github.com/gitlabhq/grit)
 * [libgit2/rugged](https://github.com/libgit2/rugged)
 * [libgit2](http://libgit2.github.com/)
 * [libgit2 API](http://libgit2.github.com/libgit2/#HEAD)
